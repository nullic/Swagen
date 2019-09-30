//
//  String+Generator.swift
//  Swagen
//
//  Created by Dmitriy Petrusevich on 9/27/19.
//  Copyright © 2019 Dmitriy Petrusevich. All rights reserved.
//

import Foundation

let reserverWords = ["Type", "Self", "self", "Codable"]
let indent = "    "


extension String {
    var escaped: String {
        return reserverWords.contains(self) ? "`\(self)`" : self
    }

    var capitalizedFirstLetter: String {
        guard self.isEmpty == false else { return self }
        return self.prefix(1).uppercased() + self.dropFirst()
    }

    var loweredFirstLetter: String {
        guard self.isEmpty == false else { return self }
        return self.prefix(1).lowercased() + self.dropFirst()
    }
}

let genFilePrefix =
"""
// Generated file

import Foundation
"""


let utilsFile =
"""
\(genFilePrefix)

extension Dictionary where Key == String, Value == Any? {
    func unopt() -> [String: Any] {
        return reduce(into: [String: Any]()) { (result, kv) in
            if let value = kv.value {
                result[kv.key] = value
            }
        }
    }
}

"""
