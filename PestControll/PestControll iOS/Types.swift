//
//  Types.swift
//  PestControll iOS
//
//  Created by Sabir Myrzaev on 08.10.2021.
//

import Foundation

enum Direction: Int {
    case forward = 0, backward, left, right
}

enum GameState: Int {
    case initial = 0, start, play, win, lose, reload, pause
}

struct PhysicsCategory {
    static let None: UInt32 = 0
    static let All: UInt32 = 0xFFFFFFFF
    static let Edge: UInt32 = 0b1
    static let Player: UInt32 = 0b10
    static let Bug: UInt32 = 0b100
    static let Firebug: UInt32 = 0b1000
    static let Breakable: UInt32 = 0b10000
}

typealias TileCoordinates = (column: Int, row: Int)
