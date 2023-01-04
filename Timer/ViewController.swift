//
//  ViewController.swift
//  Timer
//
//  Created by 김지현 on 2023/01/04.
//

import UIKit
import AudioToolbox

class ViewController: UIViewController {

    enum TimerStatus {
        
        case start
        case puase
        case end
    }
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var progress: UIProgressView!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var toggleButton: UIButton!
    
    // timer에 저장된 시간을 초로 저장하는 프로퍼티
    public var duration = 60
    
    // 현재 카운트다운 되고 있는 초를 저장하는 프로퍼티
    public var currentSeconds = 0
    
    public var timerStatus: TimerStatus = .end
    
    public var timer: DispatchSourceTimer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.configureToggleButton()
    }

    @IBAction func clickedCancelButton(_ sender: Any) {
        
        self.stopTimer()
    }
    
    @IBAction func clickedToggleButton(_ sender: Any) {
        
        self.duration = Int(self.datePicker.countDownDuration)
        
        switch self.timerStatus {
            
        case .end:
            self.currentSeconds = self.duration
            self.timerStatus = .start
            
//             self.setTimerInfoViewVisible(isHidden: false)
//             self.datePicker.isHidden = true
            
            // Animate를 이용해
            // withDuration: animation을 몇 초 동안 지속해서 사용할건지
            // duration에 closure구현: 시작 값에서 최종 값으로 변하게
            UIView.animate(withDuration: 0.5, animations: {
                self.timerLabel.alpha = 1
                self.progress.alpha = 1
                self.datePicker.alpha = 0
            })
            
            self.toggleButton.isSelected = true
            self.cancelButton.isEnabled = true
            
            self.startTimer()
            
        case .start:
            self.timerStatus = .puase
            self.toggleButton.isSelected = false
            
            self.timer?.suspend()
            
        case .puase:
            self.timerStatus = .start
            self.toggleButton.isSelected = true
            
            self.timer?.resume()
        }
    }
    
    public func setTimerInfoViewVisible(isHidden: Bool) {
         
        self.timerLabel.isHidden = isHidden
        self.progress.isHidden = isHidden
    }
    
    public func configureToggleButton() {
        
        // 버튼의 title을 초기 normal 상태에선 "시작"
        self.toggleButton.setTitle("시작", for: .normal)
        
        // 버튼이 선택되면 다른 title로
        self.toggleButton.setTitle("일시정지", for: .selected)
    }
    
    // 타이머 시작
    public func startTimer() {
        
        if self.timer == nil {
            
            // queue: 어떤 스레드에서 반복 동작을 할 것인지 설정할 수 있다
            // 우리는 타이머가 돌 때마다 UI 반복 작업을 해야한다.
            // 남은 시간, progressView도 update 해야한다.
            // 그러기에 main thread에서 반복 동작 할 수 있게 main으로 설정
            // main thread는 iOS에서 오직 한 개만 존재하는 thread
            // (대부분은 main thread에서 작동된다. 그 이유는 우리가 작성한 코드는 코코아에서 실행되는데, 이 코코아가 코드를 main thread에서 호출하기 때문)
            // main thread를 interface thread라고도 부른다. (User가 interface에 접근하면 이벤트가 main thread에 전달되고 반영)
            // -> Interface 관련된 코드는 반드시 main thread에서 작동돼야 한다. (UI작업)
            self.timer = DispatchSource.makeTimerSource(flags: [], queue: .main)
            
            // 어떤 주기로 타이머를 설정할건지
            // deadline: now() 타이머 실행시 즉시 실행
            // repeating: 몇 초마다 반복
            self.timer?.schedule(deadline: .now(), repeating: 1)
            
            // 타이머와 함께 연동된 이벤트를 설정
            // handler property에 closure함수를 구현
            // 타이머가 동작할 때마다 핸들러 함수가 호출 (즉 , 1초에 한번)
            self.timer?.setEventHandler(handler: {[weak self] in
                
                // 일시적으로 self가 strong이 되게끔 설정
                //
                guard let self = self else {
                    return
                }
                
                self.currentSeconds -= 1
                
                let hour = self.currentSeconds / 3600
                let minute = (self.currentSeconds % 3600) / 60
                let seconds = (self.currentSeconds % 3600) % 60
                
                // Timer Label Update
                self.timerLabel.text = String(format: "%02d:%02d:%02d", hour, minute, seconds)
                
                // Progress Update
                self.progress.progress = Float(self.currentSeconds) / Float(self.duration)
                
                UIView.animate(withDuration: 0.5, delay: 0, animations: {
                    
                    // CGAffineTransform은 구조체.
                    // 가장 큰 특징은 view의 frame을 계산하지 않고 2d graphic을 그릴 수 있다
                    self.imageView.transform = CGAffineTransform(rotationAngle: .pi )
                })
                UIView.animate(withDuration: 0.5, delay: 0.5, animations: {
                    self.imageView.transform = CGAffineTransform(rotationAngle: .pi * 2)
                })
                
                if self.currentSeconds <= 0 {
                    // 타이머가 종료
                    self.stopTimer()
                    AudioServicesPlaySystemSound(1005)
                }
                
            })
            
            // 타이머 호출
            self.timer?.resume()
        }
    }
    
    public func stopTimer() {
        
        // timer가 puase상태로, suspend 상태에서 nil을 할당하면 runtime err난다.
        // timer를 resume하고 nil을 설정해야 한다.
        if self.timerStatus == .puase {
            self.timer?.resume()
        }
        
        self.timerStatus = .end
        
//        self.setTimerInfoViewVisible(isHidden: true)
//        self.datePicker.isHidden = false
        
        // Animate를 이용해
        // withDuration: animation을 몇 초 동안 지속해서 사용할건지
        // duration에 closure구현: 시작 값에서 최종 값으로 변하게
        UIView.animate(withDuration: 0.5, animations: {
            self.timerLabel.alpha = 0
            self.progress.alpha = 0
            self.datePicker.alpha = 1
            
            // 이미지가 원상태로 돌아오게 설정
            self.imageView.transform = .identity
        })
        
        self.toggleButton.isSelected = false
        self.cancelButton.isEnabled = false
        
        self.timer?.cancel()
        self.timer = nil
    }
}

