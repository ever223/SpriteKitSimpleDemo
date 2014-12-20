//
//  GameOverScene.m
//  SpriteKitSimpleGame
//
//  Created by xiaoo_gan on 12/20/14.
//  Copyright (c) 2014 xiaoo_gan. All rights reserved.
//

#import "GameOverScene.h"
#import "GameScene.h"

@implementation GameOverScene
- (id) initWithSize:(CGSize)size won:(BOOL)won {
    if (self = [super initWithSize:size]) {
        //设置背景为白色
        self.backgroundColor = [SKColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];
        //  设置提醒信息
        NSString *message;
        if (won) {
            message = @"你赢啦！";
        } else {
            message = @"你输啦！";
        }
        //
        SKLabelNode *label = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];
        label.text = message;
        label.fontSize = 40;
        label.fontColor = [SKColor blackColor];
        label.position = CGPointMake(self.size.width / 2, self.size.height / 2);
        //添加标签到场景
        [self addChild:label];
        
        [self runAction:
         [SKAction sequence:@[
                              [SKAction waitForDuration:3.0],
                              [SKAction runBlock:^{
             SKTransition *reveal = [SKTransition flipHorizontalWithDuration:0.5];
             SKScene *gameScene = [[GameScene alloc] initWithSize:self.size];
             [self.view presentScene:gameScene transition:reveal];
         }]
                              ]]];
    }
    return self;
}
@end
