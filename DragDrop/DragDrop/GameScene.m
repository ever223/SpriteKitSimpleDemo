//
//  GameScene.m
//  DragDrop
//
//  Created by xiaoo_gan on 12/21/14.
//  Copyright (c) 2014 xiaoo_gan. All rights reserved.
//

#import "GameScene.h"

static NSString * const kAnimalNodeName = @"movable";

@interface GameScene ()

@property (nonatomic, strong) SKSpriteNode *background;
@property (nonatomic, strong) SKSpriteNode *selectedNode;

@end
@implementation GameScene

@synthesize background;
@synthesize selectedNode;


- (id) initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {
        //加载背景图片
        background = [SKSpriteNode spriteNodeWithImageNamed:@"blue-shooting-stars"];
        [background setName:@"background"];
        //将背景图片的anchor设置为图片的左下角（0，0）
        [background setAnchorPoint:CGPointZero];
        [self addChild:background];
        
        //加载小动物
        NSArray *imageNames = @[@"bird", @"cat", @"dog", @"turtle"];
        for (int i = 0; i < [imageNames count]; i ++) {
            NSString *imageName = [imageNames objectAtIndex:i];
            SKSpriteNode *sprite = [SKSpriteNode spriteNodeWithImageNamed:imageName];
            [sprite setName:kAnimalNodeName];
            
            float offsetFraction = ((float)(i + 1)) / ([imageNames count] + 1);
            [sprite setPosition:CGPointMake(size.width * offsetFraction, size.height / 2)];
            [background addChild:sprite];
        }
    }
    return self;
}

//- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
//    //获取触摸的位置
//    UITouch *touch = [touches anyObject];
//    CGPoint positionInScene = [touch locationInNode:self];
//    [self selectNodeFromTouch:positionInScene];
//}

- (void) selectNodeFromTouch:(CGPoint) touchLocation {
    //通过位置获得触摸的对象
    SKSpriteNode *touchedNode = (SKSpriteNode *) [self nodeAtPoint:touchLocation];
    //如果触摸不是之前的对象
    if (![selectedNode isEqual:touchedNode]) {
        //移除之前的触摸的对象的action
        [selectedNode removeAllActions];
        //并将其旋转还原
        [selectedNode runAction:[SKAction rotateToAngle:0.0f duration:0.1]];
        //当前触摸对象
        selectedNode = touchedNode;
        //左右摆动action
        if ([[touchedNode name] isEqualToString:kAnimalNodeName]) {
            SKAction * sequence = [SKAction sequence:@[[SKAction rotateByAngle:[self degToRad:-4.0f] duration:0.1],
                                                       [SKAction rotateByAngle:0.0 duration:0.1],
                                                       [SKAction rotateByAngle:[self degToRad:4.0f] duration:0.1]]];
            [selectedNode runAction:[SKAction repeatActionForever:sequence]];
        }
    }
}

//角度转化为弧度
- (float) degToRad:(float)degree {
    return degree / 180.0f * M_PI;
}

//确保不会将layer移动到背景图片范围之外。
//在这里传入一个需要移动到的位置，然后该方法会对位置做适当的判断处理，以确保不会移动太远。
- (CGPoint) boundLayerPos:(CGPoint) newPos {
    
    CGSize winSize = self.size;
    CGPoint retval = newPos;
    retval.x = MIN(retval.x, 0);
    retval.x = MAX(retval.x, -[background size].width + winSize.width);
    retval.y    = [self position].y;
    return retval;
}

- (void) panForTranslation:(CGPoint) translation {
    //获取选择对象的position
    CGPoint position = [selectedNode position];
    
    if ([[selectedNode name] isEqualToString:kAnimalNodeName]) {
        //如果是动物对象，则直接移动
        [selectedNode setPosition:CGPointMake(position.x + translation.x, position.y + translation.y)];
        
    } else {
        // 如果是背景对象
        CGPoint newPos = CGPointMake(position.x + translation.x, position.y + translation.y);
        [background setPosition:[self boundLayerPos:newPos]];
    }
}
//- (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
//    UITouch *touch = [touches anyObject];
//    
//    CGPoint positionInScene = [touch locationInNode:self];
//    NSLog(@"positionInScene:%@", NSStringFromCGPoint(positionInScene));
//    CGPoint previousPosition = [touch previousLocationInNode:self];
//    NSLog(@"previousPosition:%@",  NSStringFromCGPoint(previousPosition));
//    //计算移动的矢量
//    CGPoint translation = CGPointMake(positionInScene.x - previousPosition.x, positionInScene.y - previousPosition.y);
//    [self panForTranslation:translation];
//}
// ????
- (void)didMoveToView:(SKView *)view {
    UIPanGestureRecognizer *gestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanFrom:)];
    [[self view] addGestureRecognizer:gestureRecognizer];
}
- (void)handlePanFrom:(UIPanGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        
        CGPoint touchLocation = [recognizer locationInView:recognizer.view];
        
        touchLocation = [self convertPointFromView:touchLocation];
        
        [self selectNodeFromTouch:touchLocation];
        
        
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        
        CGPoint translation = [recognizer translationInView:recognizer.view];
        translation = CGPointMake(translation.x, -translation.y);
        [self panForTranslation:translation];
        [recognizer setTranslation:CGPointZero inView:recognizer.view];
        
    } else if (recognizer.state == UIGestureRecognizerStateEnded) {
        
        if (![[selectedNode name] isEqualToString:kAnimalNodeName]) {
            float scrollDuration = 0.2;
            CGPoint velocity = [recognizer velocityInView:recognizer.view];
            CGPoint pos = [selectedNode position];
            CGPoint p =[self mult:velocity duration:scrollDuration];
            
            CGPoint newPos = CGPointMake(pos.x + p.x, pos.y + p.y);
            newPos = [self boundLayerPos:newPos];
            [selectedNode removeAllActions];
            
            SKAction *moveTo = [SKAction moveTo:newPos duration:scrollDuration];
            [moveTo setTimingMode:SKActionTimingEaseOut];
            [selectedNode runAction:moveTo];
        }
        
    }
}
- (CGPoint) mult:(CGPoint)velocity duration:(CGFloat)scrollDuration {
    return CGPointMake(velocity.x * scrollDuration, velocity.y * scrollDuration);
}
-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
}

@end
