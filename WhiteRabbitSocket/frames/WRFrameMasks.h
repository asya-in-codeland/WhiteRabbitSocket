//
//  WRFrameMasks.h
//  WhiteRabbitSocket
//
//  Created by Anastasia Sviridenko on 06/11/2017.
//  Copyright © 2017 ASya. All rights reserved.
//

#import <Foundation/Foundation.h>

static const uint8_t WRFinMask = 0x80;
static const uint8_t WROpCodeMask = 0x0F;
static const uint8_t WRRsvMask = 0x70;
static const uint8_t WRMaskMask = 0x80;
static const uint8_t WRPayloadLenMask = 0x7F;
