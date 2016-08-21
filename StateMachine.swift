//
//  StateMachine.swift
//  TeapotTanks
//
//  Created by Joshua Smith on 8/19/16.
//  Copyright © 2016 Joshua Smith. All rights reserved.
//

import GameplayKit

class Hunting: GKState {
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        guard stateClass != Destroyed.self else {
            return true;
        }
        
        return stateClass == Targeting.self || stateClass == Destroyed.self
    }
}

class Targeting: GKState {
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        guard stateClass != Destroyed.self else {
            return true;
        }
        
        return stateClass == Hunting.self || stateClass == Reloading.self
    }
}

class Firing : GKState {
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        guard stateClass != Destroyed.self else {
            return true;
        }
        
        return stateClass == Reloading.self;
    }
}

class Reloading: GKState {
    let reloadTime = 1.0;
    var reloadRemaingingTime = 0.0;
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        guard stateClass != Destroyed.self else {
            return true;
        }
        return stateClass == Firing.self
    }
    
    override func didEnter(from previousState: GKState?) {
        reloadRemaingingTime = reloadTime;
    }
    
    override func willExit(to nextState: GKState) {
        reloadRemaingingTime = 0.0;
    }
    
    override func update(deltaTime seconds: TimeInterval) {
        reloadRemaingingTime = reloadRemaingingTime - seconds;
        if (reloadRemaingingTime < 0) {
            self.stateMachine?.enter(Targeting.self)
        }
    }
}
class Destroyed: GKState { }
