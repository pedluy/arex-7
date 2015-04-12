//
//  ObjectResult.swift
//  Lustre
//
//  Created by Zachary Waldowski on 2/7/15.
//  Copyright (c) 2014-2015. All rights reserved.
//

import Foundation

/// Container for a successful object (`T`) or a failure (`NSError`)
public enum ObjectResult<T: AnyObject> {
    case Success(T)
    case Failure(NSError)
}

extension ObjectResult: ResultType {

    public init(failure: NSError) {
        self = .Failure(failure)
    }

    public var isSuccess: Bool {
        switch self {
        case .Success: return true
        case .Failure: return false
        }
    }

    public var value: T! {
        switch self {
        case .Success(let value): return value
        case .Failure: return nil
        }
    }

    public var error: NSError? {
        switch self {
        case .Success: return nil
        case .Failure(let error): return error
        }
    }

    public func flatMap<R: ResultType>(@noescape transform: T -> R) -> R {
        switch self {
        case .Success(let value): return transform(value)
        case .Failure(let error): return failure(error)
        }
    }

}

extension ObjectResult: Printable {

    /// A textual representation of `self`.
    public var description: String {
        switch self {
        case .Success(let value): return "Success: \(value)"
        case .Failure(let error): return "Failure: \(error)"
        }
    }

}

// MARK: Remote map/flatMap

extension VoidResult {

    public func map<U: AnyObject>(@noescape getValue: () -> U) -> ObjectResult<U> {
        switch self {
        case Success:            return success(getValue())
        case Failure(let error): return failure(error)
        }
    }

}

extension ObjectResult {

    public func map<U: AnyObject>(@noescape transform: T -> U) -> ObjectResult<U> {
        switch self {
        case Success(let value): return success(transform(value))
        case Failure(let error): return failure(error)
        }
    }

}

extension AnyResult {

    public func map<U: AnyObject>(@noescape transform: T -> U) -> ObjectResult<U> {
        switch self {
        case Success(let value): return success(transform(value as! T))
        case Failure(let error): return failure(error)
        }
    }

}

// MARK: Free try

public func try<T: AnyObject>(file: StaticString = __FILE__, line: UWord = __LINE__, @noescape makeError transform: (NSError -> NSError) = identityError, @noescape fn: NSErrorPointer -> T?) -> ObjectResult<T> {
    var err: NSError?
    switch (fn(&err), err) {
    case (.Some(let value), _):
        return success(value)
    case (.None, .Some(let error)):
        return failure(transform(error))
    default:
        return failure(transform(error(file: file, line: line)))
    }
}

public func try<T: AnyObject>(file: StaticString = __FILE__, line: UWord = __LINE__, @noescape makeError transform: (NSError -> NSError) = identityError, @noescape fn: (AutoreleasingUnsafeMutablePointer<T?>, NSErrorPointer) -> Bool) -> ObjectResult<T> {
    var value: T?
    var err: NSError?
    switch (fn(&value, &err), value, err) {
    case (true, .Some(let value), _):
        return success(value)
    case (false, _, .Some(let error)):
        return failure(transform(error))
    default:
        return failure(transform(error(file: file, line: line)))
    }
}

// MARK: Free maps

public func map<IR: ResultType, U: AnyObject>(result: IR, @noescape transform: IR.Value -> U) -> ObjectResult<U> {
    if result.isSuccess {
        return success(transform(result.value))
    } else {
        return failure(result.error!)
    }
}

// MARK: Free constructors

public func success<T: AnyObject>(value: T) -> ObjectResult<T> {
    return .Success(value)
}