//
//  ActivityProgress.swift
//  CellLab
//
//  Created by Giulia Cajati on 11/11/26.
//

import Foundation
import SwiftData

enum PlayerDataV1: VersionedSchema {
    static var versionIdentifier: Schema.Version {
        Schema.Version(1, 0, 0)
    }

    static var models: [any PersistentModel.Type] {
        [ActivityProgress.self]
    }

    @Model
    final class ActivityProgress {
        @Attribute(.unique) var activityID: String
        var lastCompletedAt: Date?
        var completedContentVersion: String?

        init(activityID: String) {
            self.activityID = activityID
            self.lastCompletedAt = nil
            self.completedContentVersion = nil
        }
    }
}

typealias ActivityProgress = PlayerDataV1.ActivityProgress
