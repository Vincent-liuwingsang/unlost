//
//  DebounceObject.swift
//  unlost
//
//  Created by Wing Sang Vincent Liu on 01/07/2023.
//

import Foundation
import Combine

public final class DebounceObject: ObservableObject {
    @Published var text: String = ""
    @Published var debouncedText: String = ""
    private var bag = Set<AnyCancellable>()

    public init(dueTime: TimeInterval = 0.1) {
        $text
            .removeDuplicates()
            .debounce(for: .seconds(dueTime), scheduler: DispatchQueue.main)
            .sink(receiveValue: { [weak self] value in
                self?.debouncedText = value
            })
            .store(in: &bag)
    }
}

//public final class DebounceFunction: ObservableObject {
//    @Published var count = 0
//    private var bag = Set<AnyCancellable>()
//
//    public init(f: @escaping () -> Void, dueTime: TimeInterval = 1) {
//        $count
//            .removeDuplicates()
//            .throttle(for: .seconds(dueTime), scheduler: DispatchQueue.main, latest: true)
////            .debounce(for: .seconds(dueTime), scheduler: DispatchQueue.main)
//            .sink(receiveValue: { value in
//                f()
//            })
//            .store(in: &bag)
//    }
//}
