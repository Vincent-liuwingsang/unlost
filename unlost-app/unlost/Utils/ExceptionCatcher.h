//
//  ExceptionCatcher.h
//  unlost
//
//  Created by Wing Sang Vincent Liu on 19/09/2023.
//

#import <Foundation/Foundation.h>

#import <Foundation/Foundation.h>

NS_INLINE NSException * _Nullable tryBlock(void(^_Nonnull tryBlock)(void)) {
    @try {
        tryBlock();
    }
    @catch (NSException *exception) {
        return exception;
    }
    return nil;
}
