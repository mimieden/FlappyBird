//
//  ViewController.swift
//  FlappyBird
//
//  Created by mimieden on 2017/06/22.
//  Copyright © 2017年 mimieden. All rights reserved.
//

import UIKit
import SpriteKit  //(3.1)

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //SKViewに型を変換する(3.1)
        let L_SkView = self.view as! SKView
        
        //FPSを表示する（画面が1秒間に何回更新されているかを示すFPSを画面の右下に表示）(3.1)
        L_SkView.showsFPS = true
        
        //ノードの数を表示する（ノードが幾つ表示されているかを画面の右下に表示）(3.1)
        L_SkView.showsNodeCount = true
        
        //ビューと同じサイズでシーンを作成する(3.1)
        let L_Scene = GameScene(size:L_SkView.frame.size)  //ゲームシーンクラスに変更(5.1)同じおおきさじゃないの？
        
        //ビューにシーンを表示する(3.1)
        L_SkView.presentScene(L_Scene)
        
        //衝突判定のPhysicsBodyが見えるようにする
        L_SkView.showsPhysics = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //ステータスバーを消す(6.3)
    override var prefersStatusBarHidden: Bool {
        get {
            return true
        }
    }


}

