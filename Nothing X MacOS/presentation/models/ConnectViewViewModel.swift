//
//  ConnectViewViewModel.swift
//  Nothing X MacOS
//
//  Created by Daniel on 2025/2/27.
//
import SwiftUI
import Foundation

class ConnectViewViewModel : ObservableObject {
    
    
    private let nothingRepository: NothingRepository
    private let nothingService: NothingService
    
    @Published var isLoading = false
    @Published var isFailedToConnectPresented = false
    @Published var retry = false

    private let isBluetoothOnUseCase: IsBluetoothOnUseCaseProtocol
    @Published var isBluetoothOn = false

    private var hasAutoConnected = false
    private var watchdogTimer: DispatchWorkItem?
    private var retryCount = 0
    private let maxAutoRetries = 3
    private let watchdogTimeout: TimeInterval = 5.0
    
    
    init(nothingRepository: NothingRepository, nothingService: NothingService, bluetoothService: BluetoothService) {
        
        self.nothingRepository = nothingRepository
        self.nothingService = nothingService
        self.isBluetoothOnUseCase = IsBluetoothOnUseCase(bluetoothService: bluetoothService)
        
        NotificationCenter.default.addObserver(forName: Notification.Name(DataNotifications.REPOSITORY_DATA_UPDATED.rawValue), object: nil, queue: .main) { notification in

            self.cancelWatchdog()
            self.retryCount = 0
            self.isLoading = false

        }
        
        
        NotificationCenter.default.addObserver(forName: Notification.Name(BluetoothNotifications.FAILED_TO_CONNECT.rawValue), object: nil, queue: .main) {
            notification in
            
            
            withAnimation {
                self.isFailedToConnectPresented = true
                self.isLoading = false
            }
            
        }
        
        NotificationCenter.default.addObserver(forName: Notification.Name(Notifications.REQUEST_RETRY.rawValue), object: nil, queue: .main) {
            notification in

            self.connect()
            withAnimation {
                self.isFailedToConnectPresented = false
            }

        }

        NotificationCenter.default.addObserver(forName: Notification.Name(BluetoothNotifications.BLUETOOTH_ON.rawValue), object: nil, queue: .main) { notification in
            self.isBluetoothOn = true
            guard !self.hasAutoConnected else { return }
            self.hasAutoConnected = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.connect()
            }
        }

        NotificationCenter.default.addObserver(forName: Notification.Name(BluetoothNotifications.FAILED_RFCOMM_CHANNEL.rawValue), object: nil, queue: .main) { notification in
            self.cancelWatchdog()
            if self.retryCount < self.maxAutoRetries {
                self.retryCount += 1
                print("RFCOMM failed, auto-retry \(self.retryCount)/\(self.maxAutoRetries)")
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.isLoading = false
                    self.connect()
                }
            } else {
                withAnimation {
                    self.isFailedToConnectPresented = true
                    self.isLoading = false
                }
                self.retryCount = 0
            }
        }

    }
    
    func checkBluetoothStatus() {
        isBluetoothOn = isBluetoothOnUseCase.isBluetoothOn()
    }
    
    func connect() {
        guard !isLoading else {
            print("connect() skipped - already in progress")
            return
        }
        hasAutoConnected = true
        isLoading = true
        let devices = nothingRepository.getSaved()
        nothingService.connectToNothing(device: devices[0].bluetoothDetails)
        startWatchdog()
    }
    
    
    func retryConnect() {
        hasAutoConnected = false
        retryCount = 0
        connect()
        retry = false
        withAnimation {
            isFailedToConnectPresented = false
        }
    }

    private func startWatchdog() {
        cancelWatchdog()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            if self.isLoading {
                print("Watchdog: no data in \(self.watchdogTimeout)s, retry \(self.retryCount + 1)/\(self.maxAutoRetries)")
                if self.retryCount < self.maxAutoRetries {
                    self.retryCount += 1
                    self.nothingService.disconnect()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.isLoading = false
                        self.connect()
                    }
                } else {
                    print("Watchdog: max retries exhausted")
                    self.isLoading = false
                    withAnimation { self.isFailedToConnectPresented = true }
                    self.retryCount = 0
                }
            }
        }
        watchdogTimer = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + watchdogTimeout, execute: workItem)
    }

    private func cancelWatchdog() {
        watchdogTimer?.cancel()
        watchdogTimer = nil
    }

}
