//
//  GameScene.m
//  SpriteKitSimpleGame
//
//  Created by xiaoo_gan on 12/20/14.
//  Copyright (c) 2014 xiaoo_gan. All rights reserved.
//

#import "GameScene.h"

@interface GameScene ()
@property (nonatomic) SKSpriteNode *player;//忍者对象
@property (nonatomic) NSTimeInterval lastSpawnTimeInterval; //记录monster最近出现的时间
@property (nonatomic) NSTimeInterval lastUpdateTimeInterval;//记录上次更新的时间
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
    }
    return self;
}
- (void) addMonster {
    SKSpriteNode *monster = [SKSpriteNode spriteNodeWithImageNamed:@"Monster"];
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
    //将怪物从场景中移除
    SKAction *actionMoveDone = [SKAction removeFromParent];
    //将动作串联起来执行
    [monster runAction:[SKAction sequence:@[actionMove, actionMoveDone]]];
}
//记录上次出现monster的时间间隔
- (void) updateWithTimeSinceLastUpdate:(CFTimeInterval) timeSinceLast {
    self.lastSpawnTimeInterval += timeSinceLast;
    //如果时间大于2秒，则再添加monster到视图中
    if (self.lastSpawnTimeInterval > 2) {
        self.lastSpawnTimeInterval = 0;
        [self addMonster];
    }
}
//SpriteKit显示每帧都会调用update函数
- (void) update:(NSTimeInterval)currentTime {
    CFTimeInterval timeSinceLast = currentTime - self.lastUpdateTimeInterval;
    NSLog(@"lastUpdateTimeInterval:%f", self.lastUpdateTimeInterval);
    self.lastUpdateTimeInterval = currentTime;
    //lastUpdateTImeInterval 初始值是0.0，以下重置它的值
    if (timeSinceLast > 2) {
        timeSinceLast = 1.0;
        self.lastUpdateTimeInterval = currentTime;
    }
    [self updateWithTimeSinceLastUpdate:timeSinceLast];
}
- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    //得到触摸点的坐标
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInNode:self];
    //初始化炮弹及其位置
    SKSpriteNode *projectile = [SKSpriteNode spriteNodeWithImageNamed:@"projecticle"];
    projectile.position = self.player.position;
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
