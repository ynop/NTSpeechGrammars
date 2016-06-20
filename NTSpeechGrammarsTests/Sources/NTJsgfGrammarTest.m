//
//  NTJsgfGrammarTest.m
//  NTSpeechGrammars
//
//  Created by Matthias Büchi on 17/06/16.
//  Copyright © 2016 ZHAW Institute of Applied Information Technology. All rights reserved.
//

#import <NTSpeechGrammars/NTSpeechGrammars.h>
#import <XCTest/XCTest.h>

@interface NTJsgfGrammarTest : XCTestCase

@end

@implementation NTJsgfGrammarTest

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testParsing
{
    NTJsgfGrammar* grammar = [NTJsgfGrammar jsgfGrammarFromFile:[[NSBundle bundleForClass:self.class] pathForResource:@"test_grammar" ofType:@"jsgf"]];

    //HEADER
    XCTAssertEqualObjects(@"V1.0", grammar.version);
    XCTAssertEqualObjects(@"ISO8859-1", grammar.charset);
    XCTAssertEqualObjects(@"en", grammar.language);
    XCTAssertEqualObjects(@"com.acme.commands", grammar.name);

    //RULES
    XCTAssertEqual(6, grammar.rules.count);

    NTSpeechGrammarRule* rule1 = [self assertObject:grammar.rules[0] isRuleWithName:@"basic" scope:RULE_SCOPE_PUBLIC];
    NTSpeechGrammarRule* rule2 = [self assertObject:grammar.rules[1] isRuleWithName:@"startPolite" scope:RULE_SCOPE_PRIVATE];
    NTSpeechGrammarRule* rule3 = [self assertObject:grammar.rules[2] isRuleWithName:@"endPolite" scope:RULE_SCOPE_PRIVATE];
    NTSpeechGrammarRule* rule4 = [self assertObject:grammar.rules[3] isRuleWithName:@"command" scope:RULE_SCOPE_PRIVATE];
    NTSpeechGrammarRule* rule5 = [self assertObject:grammar.rules[4] isRuleWithName:@"action" scope:RULE_SCOPE_PRIVATE];
    NTSpeechGrammarRule* rule6 = [self assertObject:grammar.rules[5] isRuleWithName:@"object" scope:RULE_SCOPE_PRIVATE];

    //RULE 1
    NTSpeechGrammarSequence* seq = [self assertObject:rule1.root isSequenceWithCount:3];

    [self assertObject:seq.elements[0] isRuleReferenceWithName:@"startPolite"];
    [self assertObject:seq.elements[1] isRuleReferenceWithName:@"command"];
    [self assertObject:seq.elements[2] isRuleReferenceWithName:@"endPolite"];

    //RULE 2
    NTSpeechGrammarGroup* group = [self assertObject:rule2.root isGroupWithRepeatMode:REPEAT_ZERO_OR_MORE optional:NO];
    NTSpeechGrammarAlternative* alt = [self assertObject:group.root isAlternativeWithCount:4];

    [self assertObject:alt.elements[0] isTokenWithName:@"please"];
    [self assertObject:alt.elements[1] isTokenWithName:@"kindly"];
    [self assertObject:alt.elements[2] isSequenceWithTokens:@[ @"could", @"you" ]];
    [self assertObject:alt.elements[3] isSequenceWithTokens:@[ @"oh", @"mighty", @"computer" ]];

    //RULE 3
    group = [self assertObject:rule3.root isGroupWithRepeatMode:REPEAT_EXACTLY_ONCE optional:YES];
    alt = [self assertObject:group.root isAlternativeWithCount:3];

    [self assertObject:alt.elements[0] isTokenWithName:@"please"];
    [self assertObject:alt.elements[1] isTokenWithName:@"thanks"];
    [self assertObject:alt.elements[2] isSequenceWithTokens:@[ @"thank", @"you" ]];

    //RULE 4
    seq = [self assertObject:rule4.root isSequenceWithCount:2];

    [self assertObject:seq.elements[0] isRuleReferenceWithName:@"action"];
    [self assertObject:seq.elements[1] isRuleReferenceWithName:@"object"];

    //RULE 5
    alt = [self assertObject:rule5.root isAlternativeWithCount:4];
    [self assertObject:alt.elements[0] isTokenWithName:@"open" withWeight:10.0f];
    [self assertObject:alt.elements[1] isTokenWithName:@"close" withWeight:2.0f];
    [self assertObject:alt.elements[2] isTokenWithName:@"delete fast" withWeight:1.0f];
    [self assertObject:alt.elements[3] isSequenceWithTokens:@[ @"move", @"fast" ] andWeight:1.0f];

    //RULE 6
    seq = [self assertObject:rule6.root isSequenceWithCount:2];
    group = [self assertObject:seq.elements[0] isGroupWithRepeatMode:REPEAT_EXACTLY_ONCE optional:YES];
    [self assertObject:group.root isAlternativeWithTokens:@[ @"the", @"a" ]];

    group = [self assertObject:seq.elements[1] isGroupWithRepeatMode:REPEAT_EXACTLY_ONCE optional:NO];
    [self assertObject:group.root isAlternativeWithTokens:@[ @"window", @"file", @"menu" ]];
}

- (NTSpeechGrammarRule*)assertObject:(NSObject*)obj isRuleWithName:(NSString*)name scope:(NTSpeechGrammarRuleScope)scope
{
    XCTAssertTrue([obj isKindOfClass:[NTSpeechGrammarRule class]]);
    NTSpeechGrammarRule* rule = (NTSpeechGrammarRule*)obj;
    XCTAssertEqualObjects(name, rule.name);
    XCTAssertEqual(scope, rule.scope);
    return rule;
}

- (NTSpeechGrammarSequence*)assertObject:(NSObject*)obj isSequenceWithCount:(NSUInteger)count
{
    XCTAssertTrue([obj isKindOfClass:[NTSpeechGrammarSequence class]]);
    NTSpeechGrammarSequence* seq = (NTSpeechGrammarSequence*)obj;
    XCTAssertEqual(count, seq.elements.count);
    return seq;
}

- (NTSpeechGrammarSequence*)assertObject:(NSObject*)obj isSequenceWithTokens:(NSArray*)tokens
{
    XCTAssertTrue([obj isKindOfClass:[NTSpeechGrammarSequence class]]);
    NTSpeechGrammarSequence* seq = (NTSpeechGrammarSequence*)obj;

    XCTAssertEqual(tokens.count, seq.elements.count);

    for (int i = 0; i < tokens.count; i++) {
        [self assertObject:seq.elements[i] isTokenWithName:tokens[i]];
    }

    return seq;
}

- (NTSpeechGrammarSequence*)assertObject:(NSObject*)obj isSequenceWithTokens:(NSArray*)tokens andWeight:(float)weight
{
    NTSpeechGrammarSequence* seq = [self assertObject:obj isSequenceWithTokens:tokens];
    XCTAssertEqual(weight, seq.weight);
    return seq;
}

- (NTSpeechGrammarAlternative*)assertObject:(NSObject*)obj isAlternativeWithCount:(NSUInteger)count
{
    XCTAssertTrue([obj isKindOfClass:[NTSpeechGrammarAlternative class]]);
    NTSpeechGrammarAlternative* alt = (NTSpeechGrammarAlternative*)obj;
    XCTAssertEqual(count, alt.elements.count);
    return alt;
}

- (NTSpeechGrammarAlternative*)assertObject:(NSObject*)obj isAlternativeWithTokens:(NSArray*)tokens
{
    XCTAssertTrue([obj isKindOfClass:[NTSpeechGrammarAlternative class]]);
    NTSpeechGrammarAlternative* alt = (NTSpeechGrammarAlternative*)obj;

    XCTAssertEqual(tokens.count, alt.elements.count);

    for (int i = 0; i < tokens.count; i++) {
        [self assertObject:alt.elements[i] isTokenWithName:tokens[i]];
    }

    return alt;
}

- (NTSpeechGrammarGroup*)assertObject:(NSObject*)obj isGroupWithRepeatMode:(NTSpeechGrammarElementRepeatMode)repeatMode optional:(BOOL)optional
{
    XCTAssertTrue([obj isKindOfClass:[NTSpeechGrammarGroup class]]);
    NTSpeechGrammarGroup* group = (NTSpeechGrammarGroup*)obj;
    XCTAssertEqual(optional, group.isOptional);
    XCTAssertEqual(repeatMode, group.repeatMode);
    return group;
}

- (NTSpeechGrammarRuleReference*)assertObject:(NSObject*)obj isRuleReferenceWithName:(NSString*)name
{
    XCTAssertTrue([obj isKindOfClass:[NTSpeechGrammarRuleReference class]]);
    NTSpeechGrammarRuleReference* ruleRef = (NTSpeechGrammarRuleReference*)obj;
    XCTAssertEqualObjects(name, ruleRef.referencedRuleName);
    return ruleRef;
}

- (NTSpeechGrammarToken*)assertObject:(NSObject*)obj isTokenWithName:(NSString*)name
{
    XCTAssertTrue([obj isKindOfClass:[NTSpeechGrammarToken class]]);
    NTSpeechGrammarToken* token = (NTSpeechGrammarToken*)obj;
    XCTAssertEqualObjects(name, token.value);
    return token;
}

- (NTSpeechGrammarToken*)assertObject:(NSObject*)obj isTokenWithName:(NSString*)name withWeight:(float)weight
{
    NTSpeechGrammarToken* token = [self assertObject:obj isTokenWithName:name];
    XCTAssertEqual(weight, token.weight);
    return token;
}

@end
