//
//  GameScene.m
//  SpriteKitSimpleGame
//
//  Created by xiaoo_gan on 12/20/14.
//  Copyright (c) 2014 xiaoo_gan. All rights reserved.
//

#import "GameScene.h"
#import "GameOverScene.h"

//在Sprite Kit中category是一个32位整数，当做一个位掩码(bitmask)。
//这种表达方法比较奇特：在一个32位整数中的每一位表示一种类别(因此最多也就只能有32类)。
//在这里，第一位表示炮弹，下一位表示怪兽。
static const uint32_t projectileCategory = 0x1 << 0;
static const uint32_t monsterCategory = 0x1 << 1;

@interface GameScene ()
@property (nonatomic) SKSpriteNode *player;//忍者对象
@property (nonatomic) NSTimeInterval lastSpawnTimeInterval; //记录monster最近出现的时间
@property (nonatomic) NSTimeInterval lastUpdateTimeInterval;//记录上次更新的时间
@property (nonatomic) int monsterDestory;                   //记录击中的monster数量
@end

//矢量函数
// 矢量加
static inline CGPoint rwAdd(CGPoint a, CGPoint b) {
    return CGPointMake(a.x + b.x, a.y + b.y);
}
//矢量减
static inline CGPoint rwSub(CGPoint a, CGPoint b) {
    return CGPointMake(a.x - b.x, a.y - b.y);
}
//矢量乘
static inline CGPoint rwMult(CGPoint a, float b) {
    return CGPointMake(a.x * b, a.y * b);
}
//矢量长度
static inline float rwLength(CGPoint a) {
    return sqrtf(a.x * a.x + a.y * a.y);
}
// 单位矢量
static inline CGPoint rwNormalize(CGPoint a) {
    float length = rwLength(a);
    return CGPointMake(a.x / length, a.y / length);
}

@implementation GameScene

- (id) initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {
        NSLog(@"Size:%@", NSStringFromCGSize(size));
        self.backgroundColor = [SKColor colorWithRed:0.0 green:1.0 blue:1.0 alpha:1.0];
        self.player = [SKSpriteNode spriteNodeWithImageNamed:@"player"];
        NSLog(@"player's size : %@", NSStringFromCGSize(self.player.size));
        self.player.position = CGPointMake(self.player.size.width / 2, self.frame.size.height / 2);
        [self addChild:self.player];
        //设置物理世界的重力感应为0
        self.physicsWorld.gravity = CGVectorMake(0, 0);
        //将场景设置为物理世界的代理 (当有两个物体碰撞时，会收到通知)
        self.physicsWorld.contactDelegate = self;
    }
    return self;
}
- (void) addMonster {
    SKSpriteNode *monster = [SKSpriteNode spriteNodeWithImageNamed:@"Monster"];
    //为monster创建一个对应的物体。此处，物体被定义为一个与monster相同尺寸的矩形
    monster.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:monster.size];
    //设置物理引擎不再控制这个monster的运动，因为我们自己已经写好相关运动的代码了
    monster.physicsBody.dynamic = YES;
    //将category设置为之前定义好的monsterCategory
    monster.physicsBody.categoryBitMask = monsterCategory;
    //contactTestBitMask表示与什么类型对象碰撞时，应该通知contactdelegate。这里是炮弹类型
    monster.physicsBody.contactTestBitMask = projectileCategory;
    //collisionBitMask表示物理引擎需要处理的碰撞事件。
    //在此处我们不希望projectile和monster被相互弹开，故设置为0
    monster.physicsBody.collisionBitMask = 0;
    
    
    // Y min
    int minY = monster.size.height / 2;
    // Y max
    int maxY = self.frame.size.height - monster.size.height / 2;
    //max - min
    int rangeY = maxY - minY;
    int actualY = (arc4random() % rangeY) + minY;
    
    monster.position = CGPointMake(self.frame.size.width + monster.size.width / 2, actualY);
    [self addChild:monster];
    //移动持续时间在2.0秒～4.0秒之间
    int minDuration = 4.0;
    int maxDuration = 6.0;
    int rangeDuration = maxDuration - minDuration;
    int actualDuration = (arc4random() % rangeDuration) + minDuration;
    //从右边位置移到左边
    SKAction *actionMove = [SKAction moveTo:CGPointMake(-monster.size.width / 2, actualY) duration:actualDuration];
    
    //如果一个monster逃走了，则你输了
    SKAction *loseAction = [SKAction runBlock:^{
        SKTransition *reveal = [SKTransition flipHorizontalWithDuration:0.5];
        //你输了
        SKScene *gameOverScene = [[GameOverScene alloc] initWithSize:self.size won:NO];
        [self.view presentScene:gameOverScene transition:reveal];
    }];
    
    //将怪物从场景中移除
    SKAction *actionMoveDone = [SKAction removeFromParent];
//    在这里为什么loseAction要在actionMoveDone之前运行呢？
//    原因在于如果将一个精灵从场景中移除了，那么它就不在处于场景的层次结构中了，也就不会有action了。
//    所以需要过渡到lose场景之后，才能将精灵移除。
//    不过，实际上actionMoveDone永远都不会被调用——因为此时已经过渡到新的场景中了，
//    留在这里就是为了达到教学的目的。
    
    //将动作串联起来执行
    [monster runAction:[SKAction sequence:@[actionMove, loseAction, actionMoveDone]]];
}
//记录上次出现monster的时间间隔
- (void) updateWithTimeSinceLastUpdate:(CFTimeInterval) timeSinceLast {
    self.lastSpawnTimeInterval += timeSinceLast;
    //如果时间大于2秒，则再添加monster到视图中
    if (self.lastSpawnTimeInterval > 1) {
        self.lastSpawnTimeInterval = 0;
        [self addMonster];
    }
}
//SpriteKit显示每帧都会调用update函数
- (void) update:(NSTimeInterval)currentTime {
    CFTimeInterval timeSinceLast = currentTime - self.lastUpdateTimeInterval;
    //NSLog(@"lastUpdateTimeInterval:%f", self.lastUpdateTimeInterval);
    self.lastUpdateTimeInterval = currentTime;
    //lastUpdateTImeInterval 初始值是0.0，以下重置它的值
    if (timeSinceLast > 1) {
        timeSinceLast = 1.0;
        self.lastUpdateTimeInterval = currentTime;
    }
    [self updateWithTimeSinceLastUpdate:timeSinceLast];
}
- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    //设置发射炮弹的音效
    [self runAction:[SKAction playSoundFileNamed:@"pew-pew-lei.caf" waitForCompletion:NO]];
    //得到触摸点的坐标
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInNode:self];
    //初始化炮弹及其位置
    SKSpriteNode *projectile = [SKSpriteNode spriteNodeWithImageNamed:@"projectile"];
    //设置projectile的位置
    projectile.position = self.player.position;
    //为projectile设置对应的物体，此处设置与圆形
    projectile.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:projectile.size.width / 2];
    //物理引擎不再控制这个炮弹的运动，因为我们已经写好炮弹运动的代码了
    projectile.physicsBody.dynamic = YES;
    //将categoryBitMask设置为之前定义好的projectileCategory
    projectile.physicsBody.categoryBitMask = projectileCategory;
    //当炮弹与monster发生碰撞事，发出通知给contactDelegate
    projectile.physicsBody.contactTestBitMask = monsterCategory;
    //collisionBitMask表示碰撞时，物理引擎需要处理的事件
    //在此我们不希望monster和projectile碰撞相互弹开，故设置为0
    projectile.physicsBody.collisionBitMask = 0;
    //userPreciseCollisionDetection属性设置为yes。
    // 这对于快速移动的物体非常重要(例如炮弹)，如果不这样设置的话，
    //有可能快速移动的两个物体会直接相互穿过去，而不会检测到碰撞的发生。
    projectile.physicsBody.usesPreciseCollisionDetection = YES;
    
    //得到touch位置到炮弹位置的矢量
    CGPoint offset = rwSub(location, projectile.position);
    //如果在忍者左边touch，则不发射炮弹
    if (offset.x <= 0) {
        return;
    }
    //添加到视图中
    [self addChild:projectile];
    //确定发射方向 将offset转换为一个单位矢量
    CGPoint direction = rwNormalize(offset);
    //确保炮弹能发射得足够远，打到monster x 1000
    CGPoint shootAmount = rwMult(direction, 1000);
    //炮弹发射到的最终位置
    CGPoint realDest = rwAdd(shootAmount, projectile.position);
    
    //发射炮弹动作
    
    //速率
    float velocity = 480.0 / 1.0;
    //持续时间
    float realMoveDuration = self.size.width / velocity;
    //炮弹移动到realDest的动作
    SKAction *actionMove = [SKAction moveTo:realDest duration:realMoveDuration];
    //不在屏幕上，则将该炮弹移除
    SKAction *actionMoveDone = [SKAction removeFromParent];
    //为炮弹添加动作
    [projectile runAction:[SKAction sequence:@[actionMove, actionMoveDone]]];
}
//炮弹和monster碰撞时，处理的方法
- (void) projectile:(SKSpriteNode *) projectile didCollideWithMonster: (SKSpriteNode *) monster {
    NSLog(@"Hit");
    //碰撞时，将projectile和monster从场景中移除
    [projectile removeFromParent];
    [monster removeFromParent];
    //击中，则计数加一
    
    self.monsterDestory ++;
    //击中30个，就赢了
    if (self.monsterDestory > 50) {
        SKTransition *reveal = [SKTransition flipHorizontalWithDuration:0.5];
        SKScene *gameOverScene = [[GameOverScene alloc] initWithSize:self.size won:YES];
        [self.view presentScene:gameOverScene transition:reveal];
    }
    
}
- (void) didBeginContact:(SKPhysicsContact *)contact {
    SKPhysicsBody *firstBody, *secondBody;
    //将碰撞的对象分别赋给firstBody，secondBody
//    该方法会传递给你发生碰撞的两个物体，但是并不一定符合特定的顺序(如炮弹在前，或者炮弹在后)。
//    所以这里的代码是通过物体的category bit mask来对其进行排序，以便后续做出正确的判断。
//    注意，这里的代码来自苹果提供的Adventure示例。
    if (contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask) {
        firstBody = contact.bodyA;
        secondBody = contact.bodyB;
    } else {
        firstBody = contact.bodyB;
        secondBody = contact.bodyA;
    }
    //检测这两个碰撞的物体是否就是projectile和monster，如果是，就调用之前的方法
    if ((firstBody.categoryBitMask & projectileCategory) != 0 && (secondBody.categoryBitMask & monsterCategory) != 0) {
        [self projectile:(SKSpriteNode *) firstBody.node didCollideWithMonster:(SKSpriteNode *) secondBody.node];
    }
}
//-(void)didMoveToView:(SKView *)view {
//    /* Setup your scene here */
//    SKLabelNode *myLabel = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];
//    
//    myLabel.text = @"Hello, World!";
//    myLabel.fontSize = 65;
//    myLabel.position = CGPointMake(CGRectGetMidX(self.frame),
//                                   CGRectGetMidY(self.frame));
//    
//    [self addChild:myLabel];
//}
//
//-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
//    /* Called when a touch begins */
//    
//    for (UITouch *touch in touches) {
//        CGPoint location = [touch locationInNode:self];
//        
//        SKSpriteNode *sprite = [SKSpriteNode spriteNodeWithImageNamed:@"Spaceship"];
//        
//        sprite.xScale = 0.5;
//        sprite.yScale = 0.5;
//        sprite.position = location;
//        
//        SKAction *action = [SKAction rotateByAngle:M_PI duration:1];
//        
//        [sprite runAction:[SKAction repeatActionForever:action]];
//        
//        [self addChild:sprite];
//    }
//}
//
//-(void)update:(CFTimeInterval)currentTime {
//    /* Called before each frame is rendered */
//}

@end
