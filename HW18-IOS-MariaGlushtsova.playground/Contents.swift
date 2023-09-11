import Foundation

var storage = Storage()
var nsCondition = NSCondition()

private var runCount = 0

class GeneratingThread: Thread {

    override func main() {
        print("Генерирующий поток запущен")
        startTimer()
    }
    
    func startTimer() {
        var timer = Timer(timeInterval: 2, repeats: true) { timer in
            runCount += 1
            print("Генерируем чипы -> \(runCount)")
            let chip = Chip.make()
            storage.push(chip)
            
            if runCount >= 10 {
                timer.invalidate()
                print("Генерация завершена")
            }
        }
        RunLoop.current.add(timer, forMode: .default)
        RunLoop.current.run()
    }
}

class WorkThread: Thread {
    
    override func main() {
        startTimer()
    }

    private func work() {
        storage.pop()?.sodering()
    }

    private func startTimer() {
        var timer = Timer(timeInterval: 1, repeats: true) { timer in
            
            if storage.chips.count >= 1 {
                self.work()
            }

            if runCount >= 10 && storage.chips.isEmpty {
                timer.invalidate()
            }
        }
        RunLoop.current.add(timer, forMode: .default)
        RunLoop.current.run()
        print("Работа завершена. В наличии \(storage.chips.count) чипов")
    }
}


public struct Chip {
    
    public enum ChipType: UInt32 {
        case small = 1
        case medium
        case big
    }
    
    public let chipType: ChipType
    
    public static func make() -> Chip {
        guard let chipType = Chip.ChipType(rawValue: UInt32(arc4random_uniform(3) + 1)) else {
            fatalError("Incorrect random value")
        }
        return Chip(chipType: chipType)
    }
    
    public func sodering() {
        let soderingTime = chipType.rawValue
        sleep(UInt32(soderingTime))
        print("Микросхема припаяна --> осталось", storage.chips.count)
    }
}

struct Storage {
    
    public var chips = [Chip]()

    mutating func push(_ element: Chip) {
        nsCondition.lock()
        chips.append(element)
        nsCondition.unlock()
    }

    mutating func pop() -> Chip? {
        return chips.popLast()
    }

    func peek() -> Chip? {
        return chips.last
    }

    var isEmpty: Bool {
        return chips.isEmpty
    }

    var count: Int {
        return chips.count
    }
}

let generatingThread = GeneratingThread()
let workThread = WorkThread()
generatingThread.start()
workThread.start()
