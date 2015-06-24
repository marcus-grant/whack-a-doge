//
//  GameScene.m
//  whackadoge
//
//  Created by Yoseob Lee on 6/23/15.
//  Copyright (c) 2015 Yoseob Lee. All rights reserved.
//

#import "GameScene.h"

@interface GameScene () <SKPhysicsContactDelegate>
@property (nonatomic, strong) SKLabelNode *scoreBoard;
@property (nonatomic) NSUInteger score;
@property (nonatomic, strong) NSMutableArray *explosionTextures;

@end

// Returns random CGFloat in a specified range
#define ARC4RANDOM_MAX      0x100000000
static inline CGFloat RandomRange(CGFloat min, CGFloat max){
    return floorf(((double)arc4random() / ARC4RANDOM_MAX) * (max - min) + min);
}

static const uint8_t spaceshipCategory = 1;
static const uint8_t dogeCategory = 2;

@implementation GameScene

#pragma mark - Game Setup
-(instancetype)initWithSize:(CGSize)size
{
    self = [super initWithSize:size];
    
    //If initialized...
    if (self){
        
        
        [self runAction:[SKAction repeatActionForever:[SKAction sequence:@[[SKAction performSelector:@selector(spawnDoge) onTarget:self], [SKAction waitForDuration:1]]]] withKey:@"spawnDoge"];
        //spaceship action - causes exceptions upon collision
        [self runAction:[SKAction repeatActionForever:[SKAction sequence:@[[SKAction performSelector:@selector(spawnSpaceship) onTarget:self], [SKAction waitForDuration:3]]]] withKey:@"spawnSpaceship"];
        _scoreBoard = [[SKLabelNode alloc]init];
        _scoreBoard.position = CGPointMake(self.size.width/2, self.size.height - 40);
        _scoreBoard.fontColor = [UIColor whiteColor];
        _scoreBoard.fontSize = 20;
        
        self.physicsWorld.gravity = CGVectorMake(0, 0);
        self.physicsWorld.contactDelegate = self;
        
        // Load Textures
        
        SKTextureAtlas *explosionAtlas = [SKTextureAtlas atlasNamed:@"EXPLOSION"];
        NSArray *textureNames = [explosionAtlas textureNames];
        _explosionTextures = [NSMutableArray new];
        for (NSString *name in textureNames) {
            SKTexture *texture = [explosionAtlas textureNamed:name];
            [_explosionTextures addObject:texture];
        }
        
        [self addChild:_scoreBoard];
    }
    return self;
}



#pragma mark - Game Actions
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touchedNode = [touches anyObject]; // Registers the touch
    CGPoint touchPoint = [touchedNode locationInNode:self]; // (x, y) of where the touch was
    
    SKNode *node = [self nodeAtPoint:touchPoint]; // Returns the node at touch
    
    if ([node containsPoint:touchPoint]){
        [node removeFromParent];
        self.score ++;
    }
}

-(void)updateScore
{
    NSString *currentScore = [NSString stringWithFormat:@"Doges Collected: %lu", self.score];
    self.scoreBoard.text = currentScore;
}
-(void)didEvaluateActions
{
    [self updateScore];
}

-(void)spawnDoge // Spawns doge in random point on the screen
{
    SKSpriteNode *doge = [SKSpriteNode spriteNodeWithImageNamed:@"doge"];
    doge.size = CGSizeMake(65, 68.9);
    doge.position = CGPointMake(RandomRange(0, self.size.width), RandomRange(0, self.size.height - 55));
    
    doge.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:doge.size];
    doge.physicsBody.dynamic = YES;
    doge.physicsBody.categoryBitMask = dogeCategory;
    doge.physicsBody.contactTestBitMask = spaceshipCategory;
    doge.physicsBody.collisionBitMask = 0;
    
    doge.name = @"doge";
    doge.xScale = 0; // We set the x/y scale to 0 to make them invisible, used for animation to "spawn" doge (gets bigger from 0 to 1)
    doge.yScale = 0;
    [self addChild:doge];
    
    //Actions that determine just how, visually, that items animate
    //Essentially these SKActions are function pointers with parameters that the class has predefined to perform certain actions
    SKAction *appear = [SKAction scaleTo:1.0 duration:0.5];
    SKAction *disappear = [SKAction scaleTo:0.0 duration:0.5];
    //Not sure where we would use this, but I'm guessing you took it from his color-pillar example
    SKAction *waitOnScreen = [SKAction waitForDuration:.5];
    SKAction *removeFromParent = [SKAction removeFromParent];
    //TODO: Implement movingOnScreen for a constant and 'smooth' rate of motion
    //There's a way to do this 'smoother' that should be looked into later, but basically not all frames are changing at the same
    //rates so it might be pertinent later to perform the calculated amount of motion based on how much time has passed between frames
    SKAction *moveOnScreen = [SKAction moveTo:CGPointMake(RandomRange(0, self.size.width), RandomRange(0, self.size.height - 55)) duration:5];
    [doge runAction:[SKAction sequence:@[appear, waitOnScreen, moveOnScreen, disappear, removeFromParent]]]; // doge image will run through this sequence of actions
}

-(void)spawnSpaceship
{
    SKSpriteNode *spaceship = [SKSpriteNode spriteNodeWithImageNamed:@"Spaceship"];
    
    //TODO: Add scaling parameter to alter this based on settings and perhaps other game elements
    spaceship.size = CGSizeMake(50, 44); // Default size is 394 x 347
    
    CGPoint startLocation = CGPointMake(-50, RandomRange(0, self.size.height));
    spaceship.position = startLocation;
    
    spaceship.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:spaceship.size];
    spaceship.physicsBody.dynamic = NO;
    spaceship.physicsBody.categoryBitMask = spaceshipCategory;
    spaceship.physicsBody.contactTestBitMask = dogeCategory;
    spaceship.physicsBody.collisionBitMask = 0;
    
    spaceship.name = @"spaceship";
    [self addChild:spaceship];
    
    CGPoint endLocation = CGPointMake(self.size.width + 50, RandomRange(0, self.size.height)); // Where the ship will end up
    
    CGFloat angle = atan2(startLocation.y - endLocation.y, startLocation.x - endLocation.x);
    
    SKAction *rotate = [SKAction rotateToAngle:(angle + M_PI_2) duration:1];
    
    SKAction *flyBy = [SKAction moveTo:endLocation duration:5];
    SKAction *removeFromParent = [SKAction removeFromParent];
    [spaceship runAction:[SKAction sequence:@[rotate, flyBy, removeFromParent]]];
}

-(void) didBeginContact:(SKPhysicsContact *)contact
{
    SKPhysicsBody *firstBody;
    SKPhysicsBody *secondBody;
    
    if (contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask){
        firstBody = contact.bodyA;
        secondBody = contact.bodyB;
    }
    else{
        firstBody = contact.bodyB;
        secondBody = contact.bodyA;
    }
    
    if ((firstBody.categoryBitMask & spaceshipCategory) != 0){
        
        SKNode *spaceship = (contact.bodyA.categoryBitMask & spaceshipCategory) ? contact.bodyA.node : contact.bodyB.node;
        SKNode *doge = (contact.bodyA.categoryBitMask & spaceshipCategory) ? contact.bodyB.node : contact.bodyA.node;
        [spaceship runAction:[SKAction removeFromParent]];
        [doge runAction:[SKAction removeFromParent]];
        
        // add explosions
        SKSpriteNode *explosion = [SKSpriteNode spriteNodeWithTexture:[_explosionTextures objectAtIndex:0]];
        explosion.zPosition = 1;
        explosion.scale = 0.6;
        explosion.position = contact.bodyA.node.position;
        
        [self addChild:explosion];
        
        SKAction *explosionAction = [SKAction animateWithTextures:_explosionTextures timePerFrame:0.05];
        SKAction *remove = [SKAction removeFromParent];
        [explosion runAction:[SKAction sequence:@[explosionAction,remove]]];
    }
}





@end
