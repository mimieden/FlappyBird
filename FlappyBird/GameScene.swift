//
//  GameScene.swift
//  FlappyBird
//
//  Created by mimieden on 2017/06/22.
//  Copyright © 2017年 mimieden. All rights reserved.
//
//==================================================
// ノード設定
// SKNode
//  |-V_Bird(SKSpriteNode)            //宣言：class GameScene インスタンス化/追加：func F_SetUpBird
//  |-V_ScrollNode(SKNode)            //宣言：class GameScene インスタンス化/追加：func didMove
//     |-l_GroundSprite(SKSpriteNode) //宣言/インスタンス化/追加：func F_SetUpGround
//     |-l_CloudSprite(SKSpriteNode)  //宣言/インスタンス化/追加：func F_SetUpCloud
//     |-V_WallNode(SKNode)           //宣言：class GameScene インスタンス化/追加：func didMove
//        |-l_Wall(SKNode)            //宣言/インスタンス化/追加：func F_SetUpWall
//          |-l_Upper(SKSpriteNode)   //宣言/インスタンス化/追加：func F_SetUpWall
//          |-l_Under(SKSpriteNode)   //宣言/インスタンス化/追加：func F_SetUpWall
//     |-V_StarNode(SKNode)           //宣言：class GameScene インスタンス化/追加：func didMove
//        |-l_Star(SKNode)            //宣言/インスタンス化/追加：func F_SetUpStar
//          |-l_StarG1(SKSpriteNode)  //宣言/インスタンス化/追加：func F_SetUpStar
//          |-l_StarG2(SKSpriteNode)  //宣言/インスタンス化/追加：func F_SetUpStar
//          |-l_StarG3(SKSpriteNode)  //宣言/インスタンス化/追加：func F_SetUpStar
//==================================================

import SpriteKit  //import UIKitを書き換え(5.1)

//プロトコルを追加(7.4)
class GameScene: SKScene, SKPhysicsContactDelegate {
  
//==================================================
// グローバル変数/定数
//==================================================
//--ノード-------------------------------------------
    var V_ScrollNode:SKNode!  //(6.1)
    var V_WallNode:SKNode!    //(6.3)
    var V_Bird:SKSpriteNode!  //(6.4)
    var V_StarNode:SKNode!    //(課題1)
    
//--衝突カテゴリ--------------------------------------
    let L_BirdCategory:   UInt32 = 1 << 0  //0...00001
    let L_GroundCategory: UInt32 = 1 << 1  //0...00010
    let L_WallCategory:   UInt32 = 1 << 2  //0...00100
    let L_ScoreCategory:  UInt32 = 1 << 3  //0...01000 *スコア用の物体壁の間に設定し衝突したらスコアカウントアップ
    let L_ScoreStars:     UInt32 = 1 << 4  //0...10000  (課題4)
    
//--スコア用-----------------------------------------
    //スコア(Wall)
    var V_Score = 0
    var V_ScoreLabelNode: SKLabelNode!                       //(8.2)
    var V_BestScoreLabelNode: SKLabelNode!                   //(8.2)
    //スコア(Star)
    var V_ScoreStars = 0                                     //(課題4)
    var V_ScoreStarsLabelNode: SKLabelNode!                  //(課題5)
    var V_BestStarsLabelNode: SKLabelNode!                   //(課題5)
    //ユーザー初期値
    let L_UserDefaults:UserDefaults = UserDefaults.standard  //(8.1)

//==================================================
// 関数 (タイミング起動)
//==================================================
//--SKView上にシーンが表示されたときに呼ばれるメソッド(5.2)--
    override func didMove(to view: SKView) {
        
        //重力を設定(7.1)
        physicsWorld.gravity = CGVector(dx: 0.0, dy: -4.0)  //(7.1)
        physicsWorld.contactDelegate = self                 //(7.4)
        
        //背景色を設定(5.2)
        backgroundColor = UIColor(colorLiteralRed: 0.15, green: 0.75, blue: 0.90, alpha: 1)
        
        //スクロースするスプライトの親ノード(6.1)
        V_ScrollNode = SKNode()
        addChild(V_ScrollNode)
        
        //壁用のノード(6.3)
        V_WallNode = SKNode()
        V_ScrollNode.addChild(V_WallNode)
        
        //星用のノード(課題1)
        V_StarNode = SKNode()
        V_ScrollNode.addChild(V_StarNode)
        
        //各種スプライトを生成する処理をメソッドに分割(6.2)
        F_SetUpGround()      //(6.2)
        F_SetUpCloud()       //(6.2)
        F_SetUpWall()        //(6.3)
        F_SetUpStars()       //(課題1)
        F_SetUpBird()        //(6.4)
        F_SetUpScoreLabel()  //(8.2)
    }
    
//--画面をタップしたときに呼ばれるメソッド(7.3)---------------
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        //ゲーム中（= スクロールのスピード > 0）のタップ処理(7.5)
        if V_ScrollNode.speed > 0 {                                    //ゲーム中（= スクロールのスピード > 0）のタップ処理(7.5)
            V_Bird.physicsBody?.velocity = CGVector.zero               //鳥の速度を0にする(7.3)
            V_Bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 15))  //鳥に縦方向の力を与える(7.3)
            
        } else if V_Bird.speed == 0 {                                  //ゲーム中以外（= 鳥のスピード = 0）のタップ処理(7.5)
            F_Restart()
        }
    }
    
//--衝突したときに呼ばれるメソッド(7.4)----------------------
//--SKPhysicsContactDelegateのメソッド-------------------
    func didBegin(_ contact: SKPhysicsContact) {
        //ゲームオーバーのときは何もしない
        if V_ScrollNode.speed <= 0 {
            return
        }
        
        //衝突時のロジック(壁の隙間と衝突した)
        if (contact.bodyA.categoryBitMask & L_ScoreCategory) == L_ScoreCategory || (contact.bodyB.categoryBitMask & L_ScoreCategory) == L_ScoreCategory {
            
            //スコアカウントと表示
            print("ScoreUp")
            V_Score += 1
            V_ScoreLabelNode.text = "Score:\(V_Score)"  //(8.2)
            
            //ベストスコア更新か確認する(8.1)
            var v_BestScore = L_UserDefaults.integer(forKey: "BEST")
            if V_Score > v_BestScore {
                v_BestScore = V_Score
                V_BestScoreLabelNode.text = "Best Score:\(v_BestScore)"  //(8.2)
                L_UserDefaults.set(v_BestScore, forKey: "BEST")
                L_UserDefaults.synchronize()
            }
        //衝突時のロジック(星と衝突した)
        } else if ((contact.bodyA.categoryBitMask & L_ScoreStars) == L_ScoreStars || (contact.bodyB.categoryBitMask & L_ScoreStars) == L_ScoreStars){
            
            //効果音を出す
            let l_Action = SKAction.playSoundFileNamed("Star.mp3", waitForCompletion: true)
            run(l_Action)
            
            //星を削除する
            if (contact.bodyA.categoryBitMask & L_ScoreStars) == L_ScoreStars {
                contact.bodyA.node!.removeFromParent()
            } else {
                contact.bodyB.node!.removeFromParent()
            }
            
            //スコアカウントと表示
            print("Star")
            V_ScoreStars += 1
            V_ScoreStarsLabelNode.text = "Star:\(V_ScoreStars)"
            
            //ベストスコア更新か確認する
            var v_BestStars = L_UserDefaults.integer(forKey: "BESTSTARS")
            if V_ScoreStars > v_BestStars {
                v_BestStars = V_ScoreStars
                V_BestStarsLabelNode.text = "Best Stars:\(v_BestStars)"
                L_UserDefaults.set(v_BestStars, forKey: "BESTSTARS")
                L_UserDefaults.synchronize()
            }
        //衝突時のロジック(壁か地面)
        } else {
            print("GameOver")
            
            //スクロールを停止させる
            V_ScrollNode.speed = 0
            
            V_Bird.physicsBody?.collisionBitMask = L_GroundCategory
            
            let roll = SKAction.rotate(byAngle: CGFloat(Double.pi) * CGFloat(V_Bird.position.y) * 0.01, duration:1)
            V_Bird.run(roll, completion:{
                self.V_Bird.speed = 0
            })
        }
    }
    
//==================================================
// 関数（他関数からの呼び出し)
//==================================================
//--スコア表示(8.2/課題)-------------------------------
    func F_SetUpScoreLabel() {
        //現在スコア
        V_Score = 0
        V_ScoreLabelNode = SKLabelNode()
        V_ScoreLabelNode.fontColor = UIColor.black
        V_ScoreLabelNode.fontSize = 12
        V_ScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 15)
        V_ScoreLabelNode.zPosition = 100 //一番手前
        V_ScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        V_ScoreLabelNode.text = "Score:\(V_Score)"
        self.addChild(V_ScoreLabelNode)
        
        //ベストスコア
        V_BestScoreLabelNode = SKLabelNode()
        V_BestScoreLabelNode.fontColor = UIColor.black
        V_BestScoreLabelNode.fontSize = 12
        V_BestScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 45)
        V_BestScoreLabelNode.zPosition = 100 //一番手前
        V_BestScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        
        let l_BestScore = L_UserDefaults.integer(forKey: "BEST")
        V_BestScoreLabelNode.text = "Best Score:\(l_BestScore)"
        self.addChild(V_BestScoreLabelNode)
        
        //現在スター
        V_ScoreStars = 0
        V_ScoreStarsLabelNode = SKLabelNode()
        V_ScoreStarsLabelNode.fontColor = UIColor.black
        V_ScoreStarsLabelNode.fontSize = 12
        V_ScoreStarsLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 30)
        V_ScoreStarsLabelNode.zPosition = 100 //一番手前
        V_ScoreStarsLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        V_ScoreStarsLabelNode.text = "Stars:\(V_ScoreStars)"
        self.addChild(V_ScoreStarsLabelNode)
        
        //ベストスター
        V_BestStarsLabelNode = SKLabelNode()
        V_BestStarsLabelNode.fontColor = UIColor.black
        V_BestStarsLabelNode.fontSize = 12
        V_BestStarsLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 60)
        V_BestStarsLabelNode.zPosition = 100 //一番手前
        V_BestStarsLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        
        let l_BestStars = L_UserDefaults.integer(forKey: "BESTSTARS")
        V_BestStarsLabelNode.text = "Best Stars:\(l_BestStars)"
        self.addChild(V_BestStarsLabelNode)
    }
    
//--リスタート（リトライ）処理で呼ばれるメソッド(7.5)----------------------
    func F_Restart() {
        
        //スコアを0にする
        V_Score = 0
        V_ScoreLabelNode.text = String("Score:\(V_Score)")  //(8.2)
        V_ScoreStars = 0                                    //課題5
        V_ScoreStarsLabelNode.text = String("Stars:\(V_ScoreStars)")  //課題5
        
        //鳥の設定
        V_Bird.position = CGPoint(x: self.frame.size.width * 0.2, y:self.frame.size.height * 0.7)
        V_Bird.physicsBody?.velocity = CGVector.zero
        V_Bird.physicsBody?.collisionBitMask = L_GroundCategory | L_WallCategory
        V_Bird.zRotation = 0.0
        
        V_WallNode.removeAllChildren()
        V_StarNode.removeAllChildren()
        
        V_Bird.speed = 1
        V_ScrollNode.speed = 1
    }
//==================================================
// 関数（各種スプライトを生成）
//==================================================
//--地面のスクロールを関数化(6.2)------------------------
    func F_SetUpGround() {
        
        //地面の画像を読み込み(5.3)
        let l_GroundTexture = SKTexture(imageNamed: "ground")
        l_GroundTexture.filteringMode = SKTextureFilteringMode.nearest  //画像が荒くなっても処理速度を高める
        
        //必要な枚数を計算(6.1)
        let l_NeedGround = 2.0 + (frame.size.width / l_GroundTexture.size().width)
        
        //スクロールするアクションを作成(6.1)
        //左方向に画像一枚分スクロールさせるアクション(6.1)
        let l_MoveGround = SKAction.moveBy(x: -l_GroundTexture.size().width, y: 0, duration: 5.0)
        
        //元の位置に戻すアクション(6.1)
        let l_ResetGround = SKAction.moveBy(x: l_GroundTexture.size().width, y: 0, duration: 0.0)
        
        //左にスクロール→元の位置→左にスクロールと無限に切り替えるアクション(6.1)
        let L_RepeatScrollGround = SKAction.repeatForever(SKAction.sequence([l_MoveGround, l_ResetGround]))
        
        
        //groundのスプライトをスクロール付きで配置する(6.1)
        stride(from: 0.0, to: l_NeedGround, by: 1.0).forEach { i in
            
            //テクスチャを指定してスプライトを作成する(5.3)
            let l_GroundSprite = SKSpriteNode(texture: l_GroundTexture)
            
            //スプライトの表示する位置を指定する(5.3) →widthの/2を削除(6.1)
            l_GroundSprite.position = CGPoint(x: i * l_GroundSprite.size.width, y: l_GroundTexture.size().height / 2)
            
            //スプライトにアニメーションを設定する(6.1)
            l_GroundSprite.run(L_RepeatScrollGround)
            
            //スプライトに物理演算を設定する(7.2)
            l_GroundSprite.physicsBody = SKPhysicsBody(rectangleOf: l_GroundTexture.size())
            
            //衝突のカテゴリ設定(7.4)
            l_GroundSprite.physicsBody?.categoryBitMask = L_GroundCategory
            
            //衝突の時に動かないように設定する(7.2)
            l_GroundSprite.physicsBody?.isDynamic = false
            
            //シーンにスプライトを追加する(5.3) →V_ScrollNodeに追加(6.1)
            V_ScrollNode.addChild(l_GroundSprite)
        }
    }
    
//--雲のスクロールを関数化(6.2)--------------------------
    func F_SetUpCloud() {
        
        //雲の画像を読み込み(6.2)
        let l_CloudTexture = SKTexture(imageNamed: "cloud")
        l_CloudTexture.filteringMode = SKTextureFilteringMode.nearest
        
        //必要な枚数を計算(6.2)
        let l_NeedCloud = 2.0 + (frame.size.width / l_CloudTexture.size().width)
        
        //スクロールするアクションを作成(6.2)
        //左方向に画像一枚分スクロールさせるアクション(6.2)
        let l_MoveCloud = SKAction.moveBy(x: -l_CloudTexture.size().width , y: 0, duration: 20.0)
        
        //元の位置に戻すアクション(6.2)
        let l_ResetCloud = SKAction.moveBy(x: l_CloudTexture.size().width, y: 0, duration: 0.0)
        
        //左にスクロール→元の位置→左にスクロールと無限に切り替えるアクション(6.2)
        let l_RepeatScrollCloud = SKAction.repeatForever(SKAction.sequence([l_MoveCloud, l_ResetCloud]))
        
        
        //スプライトを配置する(6.2)
        stride(from: 0.0, to: l_NeedCloud, by: 1.0).forEach { i in
            
            //テクスチャを指定してスプライトを作成する(6.2)
            let l_CloudSprite = SKSpriteNode(texture: l_CloudTexture)
            
            //一番後ろになるようにする(6.2)
            l_CloudSprite.zPosition = -100
            
            //スプライトの表示する位置を指定する(6.2)
            l_CloudSprite.position = CGPoint(x: i * l_CloudSprite.size.width, y: size.height - l_CloudTexture.size().height / 2)
            
            //スプライトにアニメーションを設定する(6.2)
            l_CloudSprite.run(l_RepeatScrollCloud)
            
            //シーンにスプライトを追加する(6.2)
            V_ScrollNode.addChild(l_CloudSprite)
        }
    }
    
//--壁のスクロールを関数化(6.3)--------------------------
    func F_SetUpWall() {
        
        //壁の画像を読み込み(6.3)
        let l_WallTexture = SKTexture(imageNamed: "wall")
        l_WallTexture.filteringMode = SKTextureFilteringMode.linear //当たり判定を行うのでlinearにする
        
        //移動する距離（=画面幅＋壁の幅）を計算(6.3)
        let l_MovingDistance = CGFloat(self.frame.size.width + l_WallTexture.size().width)
        
        //画面外まで移動するアクションを作成(6.3)
        let l_MoveWall = SKAction.moveBy(x: -l_MovingDistance, y: 0, duration: 4.0)
        
        //自身を取り除くアクションを作成(6.3)
        let l_RemoveWall = SKAction.removeFromParent()
        
        //2つのアニメーションを順に実行するアクションを作成(6.3)
        let l_WallAnimation = SKAction.sequence([l_MoveWall, l_RemoveWall])
        
        //壁を生成するアクションを作成(6.3)
        let l_CreateWallAnimation = SKAction.run({
            //壁関連のノードを乗せるノードを作成(6.3)
            let l_Wall = SKNode()
            l_Wall.position = CGPoint(x: self.frame.size.width + l_WallTexture.size().width / 2, y: 0.0)
            l_Wall.zPosition = -50.0 //雲より手前、地面より奥(6.3)
            
            //画面のY軸の中央値(6.3)
            let l_Center_y = self.frame.size.height / 2
            //壁のY座標を上限ランダムにさせるときの最大値(6.3)
            let l_Random_y_Range = self.frame.size.height / 4
            //下の壁のY軸の下限(6.3)
            let l_Under_Wall_Lowest_y = UInt32 (l_Center_y - l_WallTexture.size().height / 2 -  l_Random_y_Range / 2)
            //1~_Random_y_Rangeまでのランダムな整数を生成(6.3)
            let l_Random_y = arc4random_uniform( UInt32(l_Random_y_Range) )
            //Y軸の下限にランダムな値を足して、下の壁のY座標を決定(6.3)
            let l_Under_Wall_y = CGFloat(l_Under_Wall_Lowest_y + l_Random_y)
            
            //キャラが通り抜ける隙間の長さ(6.3)
            let l_Slit_Length = self.frame.size.height / 4   //テキストでは6だが難しいので4に変更
            
            //下側の壁を作成(6.3)
            let l_Under = SKSpriteNode(texture:l_WallTexture)
            l_Under.position = CGPoint(x: 0.0, y: l_Under_Wall_y)
            l_Wall.addChild(l_Under)
            
            //スプライトに物理演算を設定する(7.2)
            l_Under.physicsBody = SKPhysicsBody(rectangleOf: l_WallTexture.size())  //(7.2)
            l_Under.physicsBody?.categoryBitMask = self.L_WallCategory              //(7.4)
            
            //衝突の時に動かないように設定する(7.2)
            l_Under.physicsBody?.isDynamic = false
            
            //上側の壁を作成(6.3)
            let l_Upper = SKSpriteNode(texture:l_WallTexture)
            l_Upper.position = CGPoint(x: 0.0, y: l_Under_Wall_y + l_WallTexture.size().height + l_Slit_Length)
            l_Wall.addChild(l_Upper)
            
            //スプライトに物理演算を設定する(7.2)
            l_Upper.physicsBody = SKPhysicsBody(rectangleOf: l_WallTexture.size())  //(7.2)
            l_Upper.physicsBody?.categoryBitMask = self.L_WallCategory              //(7.4)
            
            //衝突の時に動かないように設定する(7.2)
            l_Upper.physicsBody?.isDynamic = false
            
            //スコアアップ用のノード(7.4)
            let l_ScoreNode = SKNode()
            l_ScoreNode.position =  CGPoint(x: l_Upper.size.width + self.V_Bird.size.width / 2, y: self.frame.height / 2.0)
            l_ScoreNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: l_Upper.size.width, height: self.frame.size.height))
            l_ScoreNode.physicsBody?.isDynamic = false
            l_ScoreNode.physicsBody?.categoryBitMask = self.L_ScoreCategory
            l_ScoreNode.physicsBody?.contactTestBitMask = self.L_BirdCategory
            l_Wall.addChild(l_ScoreNode)
            
            //上下の壁にアニメーションを設定する(6.3)
            l_Wall.run(l_WallAnimation)
            
            //スプライトを追加(6.3)
            self.V_WallNode.addChild(l_Wall)
            
        })
        
        //次の壁作成までの待ち時間のアクションを作成(6.3) *Durationを2=>3にして壁の隙間を広げる(課題2)
        //(画面幅+壁の幅)*l_WaitAnimationのDuration(3)/l_MoveWallのDulation(4) が(壁の隙間+壁の幅)(課題2)
        let l_WaitAnimation = SKAction.wait(forDuration: 3)
        
        //壁を作成=>待ち時間=>壁を作成を無限に繰り返すアクションを作成(6.3)
        let l_RepeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([l_CreateWallAnimation, l_WaitAnimation]))
        
        //スプライトにアニメーションを設定する(6.3)
        V_WallNode.run(l_RepeatForeverAnimation)
    }
    
//--鳥の表示を関数化(6.4)----------------------------------
    func F_SetUpBird() {
        
        //鳥の画像を2種類読み込む(6.4)
        let l_BirdTextureA = SKTexture(imageNamed: "bird_a")
        l_BirdTextureA.filteringMode = SKTextureFilteringMode.linear //当たり判定を行うのでlinearにする
        let l_BirdTextureB = SKTexture(imageNamed: "bird_b")
        l_BirdTextureB.filteringMode = SKTextureFilteringMode.linear //当たり判定を行うのでlinearにする
        
        //2種類のテクスチャを交互に変更するアニメーションを作成(6.4)
        let l_TextureAnimation = SKAction.animate(with: [l_BirdTextureA, l_BirdTextureB], timePerFrame: 0.2)
        let l_Flap = SKAction.repeatForever(l_TextureAnimation)
        
        //スプライトを作成(6.4)
        V_Bird = SKSpriteNode(texture: l_BirdTextureA)
        V_Bird.position = CGPoint(x: self.frame.size.width * 0.2, y:self.frame.size.height * 0.7)
        
        //物理演算を設定(7.1)
        V_Bird.physicsBody = SKPhysicsBody(circleOfRadius: V_Bird.size.height / 2.0)
        
        //衝突したときに回転させない(7.4)
        V_Bird.physicsBody?.allowsRotation = false
        
        //衝突のカテゴリ設定(7.4)
        V_Bird.physicsBody?.categoryBitMask = L_BirdCategory
        V_Bird.physicsBody?.collisionBitMask = L_GroundCategory | L_WallCategory
        V_Bird.physicsBody?.contactTestBitMask = L_GroundCategory | L_WallCategory | L_ScoreStars
       
        //アニメーションを設定(6.4)
        V_Bird.run(l_Flap)
        
        //スプライトを追加する(6.4)
        addChild(V_Bird)
    }
    
//--星の表示を関数化(課題)----------------------------------
    func F_SetUpStars() {
        
        //星の画像を読み込む(課題1)
        let l_StarGTexture = SKTexture(imageNamed: "star_g")
        l_StarGTexture.filteringMode = SKTextureFilteringMode.linear //当たり判定を行うのでlinearにする
        
        //--------星のアクションを生成する-------------------
        //移動する距離（=画面幅+星の幅+消えるまでの余裕）を計算(課題1)
        var v_MoveDistance = CGFloat(self.frame.size.width + l_StarGTexture.size().width)
        v_MoveDistance *= 2  //(課題2)この幅で移動を繰り返すと星が早めに消えてしまうので幅2倍で移動を繰り返す
        
        //画面外まで移動するアクションを作成(課題1)
        let l_MoveStar = SKAction.moveBy(x: -v_MoveDistance, y: 0, duration: 8.0)  //(課題2)幅2倍にしたのでdureation 4 => 8に変更
        
        //自身を取り除くアクションを作成(課題1)
        let l_RemoveStar = SKAction.removeFromParent()
        
        //let l_WaitDeletion = SKAction.wait(forDuration:1)
        
        //2つのアニメーションを順に実行するアクションを作成(課題1)
        //let l_StarAnimation = SKAction.sequence([l_MoveStar, l_WaitDeletion, l_RemoveStar])
        let l_StarAnimation = SKAction.sequence([l_MoveStar, l_RemoveStar])

        
        //--------星を生成するアクションを作成する---------------------------------------------
        //星を生成するアクションを作成(課題1)
        let l_CreatStarAnimation = SKAction.run {
            //星ノードを乗せるノードを作成(課題1)
            let l_Star = SKNode()
            l_Star.position = CGPoint(x: self.frame.size.width + l_StarGTexture.size().width / 2, y: 0.0)  //xの位置がわからない ?
            l_Star.zPosition = -50.0                      //雲より手前、地面より奥
            
            //星の表示位置(x軸)(課題2)------------------------------------------------------
            //壁の隙間を計算(課題2)
            var v_WallToWall = self.frame.size.width + l_StarGTexture.size().width //画面幅 + 壁の幅(=星の幅)
            v_WallToWall = v_WallToWall * 3 / 4                                    //壁の隙間 + 壁の幅(=星の幅)
            v_WallToWall = v_WallToWall - l_StarGTexture.size().width              //壁の隙間
            
            //星の表示位置x軸を計算 壁の隙間に3つ (X:0.0が壁の位置→0.0+隙間の3/10,隙間の5/10,隙間の7/10) (課題2)
            var v_StarX1 = v_WallToWall * 3 / 10
            var v_StarX2 = v_WallToWall * 5 / 10
            var v_StarX3 = v_WallToWall * 7 / 10
            v_StarX1 += l_StarGTexture.size().width / 2                            //壁の幅(=星の幅)半分だけずれるので調整
            v_StarX2 += l_StarGTexture.size().width / 2                            //壁の幅(=星の幅)半分だけずれるので調整
            v_StarX3 += l_StarGTexture.size().width / 2                            //壁の幅(=星の幅)半分だけずれるので調整
            
            //星の基準表示位置(y軸)(課題3)--------------------------------------------
            //地面のTextureを取得(課題3)
            let l_GroundTexture = SKTexture(imageNamed: "ground")
            //地面の高さを取得(課題3)
            let l_GroundHeight = l_GroundTexture.size().height
            //空の高さを取得(課題3)
            let l_SkyHeight = self.frame.size.height - l_GroundHeight
            //空の中央4/5のエリアを星の表示位置としたときの下限(課題3)
            let l_StarLowest_y = l_GroundHeight + l_SkyHeight / 10
            //下限から星を表示可能な幅をレンジとして設定(課題3)
            let l_StarRange_y = l_SkyHeight * 4 / 5
            //レンジ内の値をランダムにとる(課題3)
            let l_Random_y = arc4random_uniform (UInt32(l_StarRange_y))
            //下限にランダム値を足して、基準表示位置(y軸を決定する)(課題3)
            var v_StarY = UInt32(l_StarLowest_y)
            v_StarY += l_Random_y
            let l_StarYAsCGFloat = CGFloat(v_StarY)
            //星の表示位置のランダム化(y軸)(課題3)--------------------------------------------
            //基準表示位置からずらす幅の変数(課題3)
            var v_RandomStarY1 = CGFloat(0)
            var v_RandomStarY2 = CGFloat(0)
            var v_RandomStarY3 = CGFloat(0)
            //ずらす幅をランダムに決定するために0~2のランダムな数値をとる(課題3)
            let l_Random1 = arc4random() % 3
            let l_Random2 = arc4random() % 3
            let l_Random3 = arc4random() % 3
            //0の場合は基準位置、1の場合は基準位置より星1つ分上、2の場合は基準位置より星1つ分下にずらす(課題3)
            if l_Random1 == 0 {
            } else if l_Random1 == 1 {
                v_RandomStarY1 = CGFloat(l_StarGTexture.size().height / 2)
            } else {
                v_RandomStarY1 = CGFloat(-l_StarGTexture.size().height / 2)
            }
            if l_Random2 == 0 {
            } else if l_Random2 == 1 {
                v_RandomStarY2 = CGFloat(l_StarGTexture.size().height / 2)
            } else {
                v_RandomStarY2 = CGFloat(-l_StarGTexture.size().height / 2)
            }
            if l_Random3 == 0 {
            } else if l_Random3 == 1 {
                v_RandomStarY3 = CGFloat(l_StarGTexture.size().height / 2)
            } else {
                v_RandomStarY3 = CGFloat(-l_StarGTexture.size().height / 2)
            }
            //基準位置とずらす幅から表示位置を決定(課題3)
            let l_StarY1 = l_StarYAsCGFloat + v_RandomStarY1
            let l_StarY2 = l_StarYAsCGFloat + v_RandomStarY2
            let l_StarY3 = l_StarYAsCGFloat + v_RandomStarY3
            
            
            //金の星を作成(課題1)=>金の星を3つ作成(課題2)=>星のy軸をランダム表示(課題3)
            let l_StarG1 = SKSpriteNode(texture:l_StarGTexture)
            l_StarG1.position = CGPoint(x:v_StarX1, y:l_StarY1)
            l_Star.addChild(l_StarG1)
            
            let l_StarG2 = SKSpriteNode(texture:l_StarGTexture)
            l_StarG2.position = CGPoint(x:v_StarX2, y:l_StarY2)
            l_Star.addChild(l_StarG2)
            
            let l_StarG3 = SKSpriteNode(texture:l_StarGTexture)
            l_StarG3.position = CGPoint(x:v_StarX3, y:l_StarY3)
            l_Star.addChild(l_StarG3)
            
            //金の星の衝突判定---------------------------------------------------
            //スプライトに物理演算を設定する(課題4)
            l_StarG1.physicsBody = SKPhysicsBody(circleOfRadius:l_StarGTexture.size().height / 2 )
            l_StarG2.physicsBody = SKPhysicsBody(circleOfRadius:l_StarGTexture.size().height / 2 )
            l_StarG3.physicsBody = SKPhysicsBody(circleOfRadius:l_StarGTexture.size().height / 2 )
            
            //衝突しても動かない(課題4)
            l_StarG1.physicsBody?.isDynamic = false
            l_StarG2.physicsBody?.isDynamic = false
            l_StarG3.physicsBody?.isDynamic = false
            
            //衝突のカテゴリ設定(課題4)
            l_StarG1.physicsBody?.categoryBitMask = self.L_ScoreStars
            l_StarG2.physicsBody?.categoryBitMask = self.L_ScoreStars
            l_StarG3.physicsBody?.categoryBitMask = self.L_ScoreStars
            
            //鳥との衝突(課題4)
            l_StarG1.physicsBody?.contactTestBitMask = self.L_BirdCategory
            l_StarG2.physicsBody?.contactTestBitMask = self.L_BirdCategory
            l_StarG3.physicsBody?.contactTestBitMask = self.L_BirdCategory
            
            //金の星にアクションを設定する---------------------------------------------------
            //金の星にアニメーションを設定する(課題1)=>金の星3つにアニメーションを設定(課題2)
            l_StarG1.run(l_StarAnimation)
            l_StarG2.run(l_StarAnimation)
            l_StarG3.run(l_StarAnimation)
            
            //スプライトを追加(課題1)
            self.V_StarNode.addChild(l_Star)
        }
        //--------星を生成するアクションを作成する---------------------------------------------
        //待ち時間のアクションを作成(課題1) Durationを2=>3に変更(課題2)
        //(画面幅+星の幅)*l_WaitAnimationのDuration(3)/l_MoveWallのDulation(4) が(壁の隙間+星の幅)
        let l_WaitAnimation = SKAction.wait(forDuration:3)
        
        //星を作成=>待ち時間=>星を作成を無限に繰り返すアクションを作成(課題1)
        let l_RepeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([l_CreatStarAnimation, l_WaitAnimation]))
        
        //スプライトにアニメーションを設定する(課題1)
        V_StarNode.run(l_RepeatForeverAnimation)
    }
}
