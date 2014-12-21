//
//  GameScene.m
//  AnimatedBear
//
//  Created by xiaoo_gan on 12/20/14.
//  Copyright (c) 2014 xiaoo_gan. All rights reserved.
//

#import "GameScene.h"

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

@implementation GameScene  {
    SKSpriteNode *bear;
    NSArray *bearWalkingFrames;
}

- (id) initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) { //初始化场景大小
        //设置背景颜色 黑色
        self.backgroundColor = [SKColor whiteColor];
         //构建一个用于保存行走帧的数组
        NSMutableArray *walkFrames = [NSMutableArray array];
        //加载纹理图集
        SKTextureAtlas *bearAnimatedAtlas = [SKTextureAtlas atlasNamed:@"BearImages"];
       
        //构建帧列表
        //图片个数
        int numImages = bearAnimatedAtlas.textureNames.count;
        for (int i = 1 ; i <= numImages / 2; i ++) { //除以2 获得同种分辨率的图片
            NSString *textureName = [NSString stringWithFormat:@"bear%d", i];
            SKTexture *tmp = [bearAnimatedAtlas textureNamed:textureName];
            //添加到数组
            [walkFrames addObject:tmp];
        }
        //赋给bearWalkingFrames
        bearWalkingFrames = walkFrames;
        
        //创建sprite，并将其位置设置为屏幕中间，然后添加到场景中
        SKTexture *temp = bearWalkingFrames[0];
        bear = [SKSpriteNode spriteNodeWithTexture:temp];
        bear.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame));
        [self addChild:bear];
        [self walkingBear];
    }
    return self;
}

//bear行走方法
- (void) walkingBear {
    [bear runAction:[SKAction repeatActionForever:
                     [SKAction animateWithTextures:bearWalkingFrames
                                      timePerFrame:0.1f
                                            resize:NO restore:YES]]
            withKey:@"walkingInplaceBear"]; //walkingInplaceBear这个key会强制移除动画
    return;
}
-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
}

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
//    CGPoint location  = [[touches anyObject] locationInNode:self];
//    CGFloat multiplierFOrDirection;
//    //根据点击位置控制方向
//    if (location.x <= CGRectGetMidX(self.frame)) {
//        multiplierFOrDirection = 1;
//    } else {
//        multiplierFOrDirection = -1;
//    }
//    bear.xScale = fabs(bear.xScale) * multiplierFOrDirection;
//    [self walkingBear];
    //获得触摸的位置
    CGPoint location = [[touches anyObject] locationInNode:self];
    //定义一个变量代表熊的朝向
    CGFloat multiplierForDirection;
    //设置速度
    CGSize screenSize = self.frame.size;
    float bearVelocity = screenSize.width / 3.0;
    //计算bear在X和Y轴中移动的量
    CGPoint moveDifference = CGPointMake(location.x - bear.position.x,
                                         location.y - bear.position.y);
    
    CGPoint midMoveDifference = rwMult(moveDifference, 0.5);
    CGPoint midMoveLocation = rwAdd(moveDifference,bear.position);
    //计算出实际的移动距离
    float distanceToMove = rwLength(moveDifference);
    //计算出移动实际距离所需要花费的时间
    float moveDuration = distanceToMove / bearVelocity;
    //需要的话，对bear做翻转处理
    if (moveDifference.x < 0) {
        multiplierForDirection = 1;
    } else {
        multiplierForDirection = -1;
    }
    bear.xScale = fabs(bear.xScale) * multiplierForDirection;
    
    //运行一些action
    
    //停止已有的移动action，因为要移动到别的地方
    if ([bear actionForKey:@"bearMoving"]) {
        [bear removeActionForKey:@"bearMoving"];
    }
    //如果熊还没有准备移动腿，那么就让熊的腿开始移动，否则它该如何走到新的位置呢。
    //这里使用了我们之前使用过的方法，这个方法可以确保不启动一个已经运行着的动画(以key命名)。
    if (![bear actionForKey:@"walkInPlaceBear"]) {
        [self walkingBear];
    }
    //创建一个移动action，并制定移动到何处，以及需要花费的时间。
    SKAction *moveToMidAction = [SKAction moveTo:midMoveLocation  duration:moveDuration / 3.0 + 1];
    SKAction *moveToEndAction = [SKAction moveTo:location duration:moveDuration * 2.0 / 3.0 + 1];
    //创建一个done action，当熊到达目的地后，该action利用一个block调用一个方法来停止动画。
    SKAction *doneAction = [SKAction runBlock:(dispatch_block_t)^() {
        NSLog(@"动画完成");
        [self bearMoveEnd];
    }];
    //将上面的两个action设置为一个顺序action链，
    //就是说让这两个action按照先后顺序运行(第一个运行完之后，再运行第二个)。
    SKAction *moveActionWithDone = [SKAction sequence:@[moveToMidAction, moveToEndAction, doneAction]];
    //让熊开始运行action，并制定一个key为：”bearMoving”。
    //记住，这里的key用来判断熊是否需要移动到新的位置。
    [bear runAction:moveActionWithDone withKey:@"bearMoving"];
}
- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
}
- (void) bearMoveEnd {
    [bear removeAllActions];
}

@end






















