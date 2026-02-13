//
//  Base.swift
//  BluetoothTest
//
//  Created by Daniel on 2025/2/13.
//

enum Codenames : String, Codable {
    case UNKNOWN = "0000"
    case ONE = "B181"
    case STICKS = "B157"
    case TWO = "B155"
    case CORSOLA = "B163"
    case TWOS = "B171"
    case ESPEON = "B172"
    case DONPHAN = "B168"
    case FLAFFY = "B174"
    case CLEFFA = "B162"
    case EAR_3 = "B173"

    var displayName: String {
        switch self {
        case .ONE: return "ear (1)"
        case .STICKS: return "ear (stick)"
        case .TWO: return "ear (2)"
        case .CORSOLA: return "CMF Buds Pro"
        case .TWOS: return "ear"
        case .ESPEON: return "CMF Buds Pro 2"
        case .DONPHAN: return "CMF Buds"
        case .FLAFFY: return "ear (open)"
        case .CLEFFA: return "ear (a)"
        case .EAR_3: return "ear (3)"
        case .UNKNOWN: return "ear (1)"
        }
    }
}
