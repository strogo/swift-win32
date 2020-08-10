/**
 * Copyright © 2019 Saleem Abdulrasool <compnerd@compnerd.org>
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * 3. The name of the author may not be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR "AS IS" AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 * EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 **/

private protocol ControlEventCallable {
  func callAsFunction(sender: Button, event: Control.Event)
}

private struct ControlEventCallback<Target: AnyObject>: ControlEventCallable {
  private unowned(safe) let instance: Target
  private let method: (Target) -> (_: Button, _: Control.Event) -> Void

  public init(binding: @escaping (Target) -> (_: Button, _: Control.Event) -> Void,
              on: Target) {
    self.instance = on
    self.method = binding
  }

  public init(binding: @escaping (Target) -> (_: Button) -> Void, on: Target) {
    self.instance = on
    self.method = { (target: Target) in { (sender: Button, _: Control.Event) in
        binding(target)(sender)
      }
    }
  }

  public init(binding: @escaping (Target) -> () -> Void, on: Target) {
    self.instance = on
    self.method = { (target: Target) in { (_: Button, _: Control.Event) in
        binding(target)()
      }
    }
  }

  public func callAsFunction(sender: Button, event: Control.Event) {
    self.method(instance)(sender, event)
  }
}

public class Control: View {
  private var actions: [Control.Event:[ControlEventCallable]] = [:]

  /// Accessing the Control's Targets and Actions
  public let allControlEvents: Control.Event = Control.Event(rawValue: 0)

  public func addTarget<Target: AnyObject>(_ target: Target,
                                           action: @escaping (Target) -> () -> Void,
                                           for controlEvents: Control.Event) {
    assert(controlEvents.rawValue.nonzeroBitCount == 1,
           "need to unpack controlEvents")
    var events = self.actions[controlEvents] ?? []
    events.append(ControlEventCallback(binding: action, on: target))
    self.actions[controlEvents] = events
  }

  public func addTarget<Target: AnyObject>(_ target: Target,
                                           action: @escaping (Target) -> (_: Button) -> Void,
                                           for controlEvents: Control.Event) {
    assert(controlEvents.rawValue.nonzeroBitCount == 1,
           "need to unpack controlEvents")
    var events = self.actions[controlEvents] ?? []
    events.append(ControlEventCallback(binding: action, on: target))
    self.actions[controlEvents] = events
  }

  public func addTarget<Target: AnyObject>(_ target: Target,
                                           action: @escaping (Target) -> (_: Button, _: Control.Event) -> Void,
                                           for controlEvents: Control.Event) {
    _ = ControlEventCallback(binding: action, on: target)
  }

  /// Triggering Actions
  func sendActions(for controlEvents: Control.Event) {
    assert(controlEvents.rawValue.nonzeroBitCount == 1,
           "need to unpack controlEvents")
    _ = self.actions[controlEvents]?.map { $0(sender: self as! Button,
                                           event: controlEvents) }
  }
}

public extension Control {
  struct State: OptionSet {
    public let rawValue: Int

    public init(rawValue: Int) {
      self.rawValue = rawValue
    }
  }
}

public extension Control.State {
  static let normal: Control.State = Control.State(rawValue: 1 << 0)
  static let highlighted: Control.State = Control.State(rawValue: 1 << 1)
  static let disabled: Control.State = Control.State(rawValue: 1 << 2)
  static let selected: Control.State = Control.State(rawValue: 1 << 3)
  static let focused: Control.State = Control.State(rawValue: 1 << 4)
  static let application: Control.State = Control.State(rawValue: 1 << 5)
  static let reserved: Control.State = Control.State(rawValue: 1 << 6)
}
