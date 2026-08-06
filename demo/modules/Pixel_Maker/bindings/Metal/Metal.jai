/*

:AwfulCopyPasta

Wow, this file is just a huge pile of the same 4-line wrapper pasted over and over.
This should be done in a more economical fashion, either with a macro or code generation,
or ... something.      -jblow, 17 March 2021.

*/

init_metal :: () {
    if __selectors.layer return;

    init_objective_c_selector_struct(*__selectors);
}

#scope_module

#import "Basic";
#import "Objective_C";

CGColorSpaceRef :: *void;
IOSurfaceRef :: *void;


// NOTE: it may be the case that some of the calls to objc_msgSend are incorrect due to
// some calls requiring being made to objc_msgSend_fpret or objc_msgSend_stret and jaicc
// not yet being able to automatically figure out which one to use. -josh 24 January 2019

#scope_file
// @Cleanup, stdint declarations should be moved elsewhere or removed entirely.
uint32_t :: u32;
uint64_t :: u64;
uint16_t :: u16;
uint8_t :: u8;
int32_t :: s32;

U64_MAX : u64 : 0xffff_ffff_ffff_ffff;
#scope_export

DISPATCH_TIME_NOW : u64 : 0;
DISPATCH_TIME_FOREVER := U64_MAX; // (~0ull)

dispatch_time_t             :: u64;
dispatch_semaphore_t        :: *NSObject;
dispatch_semaphore_create   :: (value: s32) -> dispatch_semaphore_t #foreign Metal;
dispatch_semaphore_wait     :: (dsema: dispatch_semaphore_t, timeout: dispatch_time_t) #foreign Metal;
dispatch_semaphore_signal   :: (dsema: dispatch_semaphore_t) -> s32 #foreign Metal;


CAMetalDrawable :: struct {
    texture :: (self: *CAMetalDrawable) -> id {
        _func: (obj: *void, selector: *void) -> id #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.texture);
    }

    layer :: (self: *CAMetalDrawable) -> *CAMetalLayer {
        _func: (obj: *void, selector: *void) -> *CAMetalLayer #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.layer);
    }
}

CAMetalLayer :: struct {
    using calayer: CALayer;
    _priv: *_CAMetalLayerPrivate;

    layer :: (self: *CAMetalLayer) -> *CAMetalLayer {
        _func: (obj: *void, selector: *void) -> *CAMetalLayer #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.layer);
    }

    nextDrawable :: (self: *CAMetalLayer) -> *CAMetalDrawable {
        _func: (obj: *void, selector: *void) -> *CAMetalDrawable #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.nextDrawable);
    }

    device :: (self: *CAMetalLayer) -> *MTLDevice {
        _func: (obj: *void, selector: *void) -> *MTLDevice #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.device);
    }

    setDevice :: (self: *CAMetalLayer, device: *MTLDevice) -> () {
        _func: (obj: *void, selector: *void, device: *MTLDevice) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setDevice_, device);
    }

    pixelFormat :: (self: *CAMetalLayer) -> MTLPixelFormat {
        _func: (obj: *void, selector: *void) -> MTLPixelFormat #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.pixelFormat);
    }

    setPixelFormat :: (self: *CAMetalLayer, pixelFormat: MTLPixelFormat) -> () {
        _func: (obj: *void, selector: *void, pixelFormat: MTLPixelFormat) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setPixelFormat_, pixelFormat);
    }

    framebufferOnly :: (self: *CAMetalLayer) -> BOOL {
        _func: (obj: *void, selector: *void) -> BOOL #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.framebufferOnly);
    }

    setFramebufferOnly :: (self: *CAMetalLayer, framebufferOnly: BOOL) -> () {
        _func: (obj: *void, selector: *void, framebufferOnly: BOOL) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setFramebufferOnly_, framebufferOnly);
    }

    drawableSize :: (self: *CAMetalLayer) -> CGSize {
        _func: (obj: *void, selector: *void) -> CGSize #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.drawableSize);
    }

    setDrawableSize :: (self: *CAMetalLayer, drawableSize: CGSize) -> () {
        _func: (obj: *void, selector: *void, drawableSize: CGSize) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setDrawableSize_, drawableSize);
    }

    maximumDrawableCount :: (self: *CAMetalLayer) -> NSUInteger {
        _func: (obj: *void, selector: *void) -> NSUInteger #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.maximumDrawableCount);
    }

    setMaximumDrawableCount :: (self: *CAMetalLayer, maximumDrawableCount: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, maximumDrawableCount: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setMaximumDrawableCount_, maximumDrawableCount);
    }

    presentsWithTransaction :: (self: *CAMetalLayer) -> BOOL {
        _func: (obj: *void, selector: *void) -> BOOL #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.presentsWithTransaction);
    }

    setPresentsWithTransaction :: (self: *CAMetalLayer, presentsWithTransaction: BOOL) -> () {
        _func: (obj: *void, selector: *void, presentsWithTransaction: BOOL) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setPresentsWithTransaction_, presentsWithTransaction);
    }

    colorspace :: (self: *CAMetalLayer) -> CGColorSpaceRef {
        _func: (obj: *void, selector: *void) -> CGColorSpaceRef #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.colorspace);
    }

    setColorspace :: (self: *CAMetalLayer, colorspace: CGColorSpaceRef) -> () {
        _func: (obj: *void, selector: *void, colorspace: CGColorSpaceRef) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setColorspace_, colorspace);
    }

    wantsExtendedDynamicRangeContent :: (self: *CAMetalLayer) -> BOOL {
        _func: (obj: *void, selector: *void) -> BOOL #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.wantsExtendedDynamicRangeContent);
    }

    setWantsExtendedDynamicRangeContent :: (self: *CAMetalLayer, wantsExtendedDynamicRangeContent: BOOL) -> () {
        _func: (obj: *void, selector: *void, wantsExtendedDynamicRangeContent: BOOL) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setWantsExtendedDynamicRangeContent_, wantsExtendedDynamicRangeContent);
    }

    displaySyncEnabled :: (self: *CAMetalLayer) -> BOOL {
        _func: (obj: *void, selector: *void) -> BOOL #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.displaySyncEnabled);
    }

    setDisplaySyncEnabled :: (self: *CAMetalLayer, displaySyncEnabled: BOOL) -> () {
        _func: (obj: *void, selector: *void, displaySyncEnabled: BOOL) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setDisplaySyncEnabled_, displaySyncEnabled);
    }

    allowsNextDrawableTimeout :: (self: *CAMetalLayer) -> BOOL {
        _func: (obj: *void, selector: *void) -> BOOL #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.allowsNextDrawableTimeout);
    }

    setAllowsNextDrawableTimeout :: (self: *CAMetalLayer, allowsNextDrawableTimeout: BOOL) -> () {
        _func: (obj: *void, selector: *void, allowsNextDrawableTimeout: BOOL) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setAllowsNextDrawableTimeout_, allowsNextDrawableTimeout);
    }

}

_CAMetalLayerPrivate :: struct {
}




MTLOrigin :: struct {
    x: NSUInteger;
    y: NSUInteger;
    z: NSUInteger;
}

MTLOriginMake :: inline (x: NSUInteger, y: NSUInteger, z: NSUInteger) -> MTLOrigin {
    origin: MTLOrigin = ---;
    origin.x = x;
    origin.y = y;
    origin.z = z;
    return origin;
}

MTLSize :: struct {
    width: NSUInteger;
    height: NSUInteger;
    depth: NSUInteger;
}

MTLSizeMake :: inline (width: NSUInteger, height: NSUInteger, depth: NSUInteger) -> MTLSize {
    size: MTLSize = ---;
    size.width  = width;
    size.height = height;
    size.depth = depth;
    return size;
}

MTLRegion :: struct {
    origin: MTLOrigin;
    size: MTLSize;
}

MTLRegionMake1D :: inline (x: NSUInteger, width: NSUInteger) -> MTLRegion {
    region: MTLRegion = ---;
    region.origin.x = x;
    region.origin.y = 0;
    region.origin.z = 0;

    region.size.width = width;
    region.size.height = 1;
    region.size.depth = 1;
    return region;
}

MTLRegionMake2D :: inline (x: NSUInteger, y: NSUInteger, width: NSUInteger, height: NSUInteger) -> MTLRegion {
    region: MTLRegion = ---;
    region.origin.x = x;
    region.origin.y = y;
    region.origin.z = 0;

    region.size.width = width;
    region.size.height = height;
    region.size.depth = 1;
    return region;
}

MTLRegionMake3D :: inline (x: NSUInteger, y: NSUInteger, z: NSUInteger, width: NSUInteger, height: NSUInteger, depth: NSUInteger) -> MTLRegion {
    region: MTLRegion = ---;
    region.origin.x = x;
    region.origin.y = y;
    region.origin.z = z;

    region.size.width = width;
    region.size.height = height;
    region.size.depth = depth;
    return region;
}

MTLSamplePosition :: struct {
    x: float32;
    y: float32;
}

MTLSamplePositionMake :: inline (x: float, y: float) -> MTLSamplePosition {
    position: MTLSamplePosition = ---;
    position.x = x;
    position.y = y;
    return position;
}

using MTLResourceUsage :: enum NSUInteger {
    MTLResourceUsageRead :: 1;
    MTLResourceUsageWrite :: 2;
    MTLResourceUsageSample :: 4;
}

using MTLBarrierScope :: enum NSUInteger {
    MTLBarrierScopeBuffers :: 1;
    MTLBarrierScopeTextures :: 2;
    MTLBarrierScopeRenderTargets :: 4;
}

MTLCommandEncoder :: struct {
    endEncoding :: (self: *MTLCommandEncoder) -> () {
        _func: (obj: *void, selector: *void) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.endEncoding);
    }

    insertDebugSignpost :: (self: *MTLCommandEncoder, _string: *NSString) -> () {
        _func: (obj: *void, selector: *void, _string: *NSString) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.insertDebugSignpost_, _string);
    }

    pushDebugGroup :: (self: *MTLCommandEncoder, _string: *NSString) -> () {
        _func: (obj: *void, selector: *void, _string: *NSString) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.pushDebugGroup_, _string);
    }

    popDebugGroup :: (self: *MTLCommandEncoder) -> () {
        _func: (obj: *void, selector: *void) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.popDebugGroup);
    }

    device :: (self: *MTLCommandEncoder) -> id {
        _func: (obj: *void, selector: *void) -> id #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.device);
    }

    label :: (self: *MTLCommandEncoder) -> *NSString {
        _func: (obj: *void, selector: *void) -> *NSString #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.label);
    }

    setLabel :: (self: *MTLCommandEncoder, label: *NSString) -> () {
        _func: (obj: *void, selector: *void, label: *NSString) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setLabel_, label);
    }

}

using MTLPixelFormat :: enum NSUInteger {
    MTLPixelFormatInvalid :: 0;
    MTLPixelFormatA8Unorm :: 1;
    MTLPixelFormatR8Unorm :: 10;
    MTLPixelFormatR8Unorm_sRGB :: 11;
    MTLPixelFormatR8Snorm :: 12;
    MTLPixelFormatR8Uint :: 13;
    MTLPixelFormatR8Sint :: 14;
    MTLPixelFormatR16Unorm :: 20;
    MTLPixelFormatR16Snorm :: 22;
    MTLPixelFormatR16Uint :: 23;
    MTLPixelFormatR16Sint :: 24;
    MTLPixelFormatR16Float :: 25;
    MTLPixelFormatRG8Unorm :: 30;
    MTLPixelFormatRG8Unorm_sRGB :: 31;
    MTLPixelFormatRG8Snorm :: 32;
    MTLPixelFormatRG8Uint :: 33;
    MTLPixelFormatRG8Sint :: 34;
    MTLPixelFormatB5G6R5Unorm :: 40;
    MTLPixelFormatA1BGR5Unorm :: 41;
    MTLPixelFormatABGR4Unorm :: 42;
    MTLPixelFormatBGR5A1Unorm :: 43;
    MTLPixelFormatR32Uint :: 53;
    MTLPixelFormatR32Sint :: 54;
    MTLPixelFormatR32Float :: 55;
    MTLPixelFormatRG16Unorm :: 60;
    MTLPixelFormatRG16Snorm :: 62;
    MTLPixelFormatRG16Uint :: 63;
    MTLPixelFormatRG16Sint :: 64;
    MTLPixelFormatRG16Float :: 65;
    MTLPixelFormatRGBA8Unorm :: 70;
    MTLPixelFormatRGBA8Unorm_sRGB :: 71;
    MTLPixelFormatRGBA8Snorm :: 72;
    MTLPixelFormatRGBA8Uint :: 73;
    MTLPixelFormatRGBA8Sint :: 74;
    MTLPixelFormatBGRA8Unorm :: 80;
    MTLPixelFormatBGRA8Unorm_sRGB :: 81;
    MTLPixelFormatRGB10A2Unorm :: 90;
    MTLPixelFormatRGB10A2Uint :: 91;
    MTLPixelFormatRG11B10Float :: 92;
    MTLPixelFormatRGB9E5Float :: 93;
    MTLPixelFormatBGR10A2Unorm :: 94;
    MTLPixelFormatBGR10_XR :: 554;
    MTLPixelFormatBGR10_XR_sRGB :: 555;
    MTLPixelFormatRG32Uint :: 103;
    MTLPixelFormatRG32Sint :: 104;
    MTLPixelFormatRG32Float :: 105;
    MTLPixelFormatRGBA16Unorm :: 110;
    MTLPixelFormatRGBA16Snorm :: 112;
    MTLPixelFormatRGBA16Uint :: 113;
    MTLPixelFormatRGBA16Sint :: 114;
    MTLPixelFormatRGBA16Float :: 115;
    MTLPixelFormatBGRA10_XR :: 552;
    MTLPixelFormatBGRA10_XR_sRGB :: 553;
    MTLPixelFormatRGBA32Uint :: 123;
    MTLPixelFormatRGBA32Sint :: 124;
    MTLPixelFormatRGBA32Float :: 125;
    MTLPixelFormatBC1_RGBA :: 130;
    MTLPixelFormatBC1_RGBA_sRGB :: 131;
    MTLPixelFormatBC2_RGBA :: 132;
    MTLPixelFormatBC2_RGBA_sRGB :: 133;
    MTLPixelFormatBC3_RGBA :: 134;
    MTLPixelFormatBC3_RGBA_sRGB :: 135;
    MTLPixelFormatBC4_RUnorm :: 140;
    MTLPixelFormatBC4_RSnorm :: 141;
    MTLPixelFormatBC5_RGUnorm :: 142;
    MTLPixelFormatBC5_RGSnorm :: 143;
    MTLPixelFormatBC6H_RGBFloat :: 150;
    MTLPixelFormatBC6H_RGBUfloat :: 151;
    MTLPixelFormatBC7_RGBAUnorm :: 152;
    MTLPixelFormatBC7_RGBAUnorm_sRGB :: 153;
    MTLPixelFormatPVRTC_RGB_2BPP :: 160;
    MTLPixelFormatPVRTC_RGB_2BPP_sRGB :: 161;
    MTLPixelFormatPVRTC_RGB_4BPP :: 162;
    MTLPixelFormatPVRTC_RGB_4BPP_sRGB :: 163;
    MTLPixelFormatPVRTC_RGBA_2BPP :: 164;
    MTLPixelFormatPVRTC_RGBA_2BPP_sRGB :: 165;
    MTLPixelFormatPVRTC_RGBA_4BPP :: 166;
    MTLPixelFormatPVRTC_RGBA_4BPP_sRGB :: 167;
    MTLPixelFormatEAC_R11Unorm :: 170;
    MTLPixelFormatEAC_R11Snorm :: 172;
    MTLPixelFormatEAC_RG11Unorm :: 174;
    MTLPixelFormatEAC_RG11Snorm :: 176;
    MTLPixelFormatEAC_RGBA8 :: 178;
    MTLPixelFormatEAC_RGBA8_sRGB :: 179;
    MTLPixelFormatETC2_RGB8 :: 180;
    MTLPixelFormatETC2_RGB8_sRGB :: 181;
    MTLPixelFormatETC2_RGB8A1 :: 182;
    MTLPixelFormatETC2_RGB8A1_sRGB :: 183;
    MTLPixelFormatASTC_4x4_sRGB :: 186;
    MTLPixelFormatASTC_5x4_sRGB :: 187;
    MTLPixelFormatASTC_5x5_sRGB :: 188;
    MTLPixelFormatASTC_6x5_sRGB :: 189;
    MTLPixelFormatASTC_6x6_sRGB :: 190;
    MTLPixelFormatASTC_8x5_sRGB :: 192;
    MTLPixelFormatASTC_8x6_sRGB :: 193;
    MTLPixelFormatASTC_8x8_sRGB :: 194;
    MTLPixelFormatASTC_10x5_sRGB :: 195;
    MTLPixelFormatASTC_10x6_sRGB :: 196;
    MTLPixelFormatASTC_10x8_sRGB :: 197;
    MTLPixelFormatASTC_10x10_sRGB :: 198;
    MTLPixelFormatASTC_12x10_sRGB :: 199;
    MTLPixelFormatASTC_12x12_sRGB :: 200;
    MTLPixelFormatASTC_4x4_LDR :: 204;
    MTLPixelFormatASTC_5x4_LDR :: 205;
    MTLPixelFormatASTC_5x5_LDR :: 206;
    MTLPixelFormatASTC_6x5_LDR :: 207;
    MTLPixelFormatASTC_6x6_LDR :: 208;
    MTLPixelFormatASTC_8x5_LDR :: 210;
    MTLPixelFormatASTC_8x6_LDR :: 211;
    MTLPixelFormatASTC_8x8_LDR :: 212;
    MTLPixelFormatASTC_10x5_LDR :: 213;
    MTLPixelFormatASTC_10x6_LDR :: 214;
    MTLPixelFormatASTC_10x8_LDR :: 215;
    MTLPixelFormatASTC_10x10_LDR :: 216;
    MTLPixelFormatASTC_12x10_LDR :: 217;
    MTLPixelFormatASTC_12x12_LDR :: 218;
    MTLPixelFormatGBGR422 :: 240;
    MTLPixelFormatBGRG422 :: 241;
    MTLPixelFormatDepth16Unorm :: 250;
    MTLPixelFormatDepth32Float :: 252;
    MTLPixelFormatStencil8 :: 253;
    MTLPixelFormatDepth24Unorm_Stencil8 :: 255;
    MTLPixelFormatDepth32Float_Stencil8 :: 260;
    MTLPixelFormatX32_Stencil8 :: 261;
    MTLPixelFormatX24_Stencil8 :: 262;
}

using MTLPurgeableState :: enum NSUInteger {
    MTLPurgeableStateKeepCurrent :: 1;
    MTLPurgeableStateNonVolatile :: 2;
    MTLPurgeableStateVolatile :: 3;
    MTLPurgeableStateEmpty :: 4;
}

using MTLCPUCacheMode :: enum NSUInteger {
    MTLCPUCacheModeDefaultCache :: 0;
    MTLCPUCacheModeWriteCombined :: 1;
}

using MTLStorageMode :: enum NSUInteger {
    MTLStorageModeShared :: 0;
    MTLStorageModeManaged :: 1;
    MTLStorageModePrivate :: 2;
    MTLStorageModeMemoryless :: 3;
}

using MTLResourceOptions :: enum NSUInteger {
    MTLResourceCPUCacheModeDefaultCache :: 0;
    MTLResourceCPUCacheModeWriteCombined :: 1;
    MTLResourceStorageModeShared :: 0;
    MTLResourceStorageModeManaged :: 16;
    MTLResourceStorageModePrivate :: 32;
    MTLResourceStorageModeMemoryless :: 48;
    MTLResourceHazardTrackingModeUntracked :: 256;
    MTLResourceOptionCPUCacheModeDefault :: 0;
    MTLResourceOptionCPUCacheModeWriteCombined :: 1;
}

MTLResource :: struct {
    setPurgeableState :: (self: *MTLResource, state: MTLPurgeableState) -> MTLPurgeableState {
        _func: (obj: *void, selector: *void, state: MTLPurgeableState) -> MTLPurgeableState #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.setPurgeableState_, state);
    }

    makeAliasable :: (self: *MTLResource) -> () {
        _func: (obj: *void, selector: *void) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.makeAliasable);
    }

    isAliasable :: (self: *MTLResource) -> BOOL {
        _func: (obj: *void, selector: *void) -> BOOL #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.isAliasable);
    }

    label :: (self: *MTLResource) -> *NSString {
        _func: (obj: *void, selector: *void) -> *NSString #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.label);
    }

    setLabel :: (self: *MTLResource, label: *NSString) -> () {
        _func: (obj: *void, selector: *void, label: *NSString) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setLabel_, label);
    }

    device :: (self: *MTLResource) -> id {
        _func: (obj: *void, selector: *void) -> id #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.device);
    }

    cpuCacheMode :: (self: *MTLResource) -> MTLCPUCacheMode {
        _func: (obj: *void, selector: *void) -> MTLCPUCacheMode #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.cpuCacheMode);
    }

    storageMode :: (self: *MTLResource) -> MTLStorageMode {
        _func: (obj: *void, selector: *void) -> MTLStorageMode #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.storageMode);
    }

    heap :: (self: *MTLResource) -> id {
        _func: (obj: *void, selector: *void) -> id #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.heap);
    }

    allocatedSize :: (self: *MTLResource) -> NSUInteger {
        _func: (obj: *void, selector: *void) -> NSUInteger #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.allocatedSize);
    }

}

MTLBuffer :: struct {
    using MTLResourceUsage;

    setLabel :: (self: *MTLBuffer, label: *NSString) -> () {
        _func: (obj: *void, selector: *void, label: *NSString) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setLabel_, label);
    }

    contents :: (self: *MTLBuffer) -> *void {
        _func: (obj: *void, selector: *void) -> *void #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.contents);
    }

    didModifyRange :: (self: *MTLBuffer, range: NSRange) -> () {
        _func: (obj: *void, selector: *void, range: NSRange) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.didModifyRange_, range);
    }

    newTextureWithDescriptor_offset_bytesPerRow :: (self: *MTLBuffer, descriptor: *MTLTextureDescriptor, offset: NSUInteger, bytesPerRow: NSUInteger) -> id {
        _func: (obj: *void, selector: *void, descriptor: *MTLTextureDescriptor, offset: NSUInteger, bytesPerRow: NSUInteger) -> id #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.newTextureWithDescriptor_offset_bytesPerRow_, descriptor, offset, bytesPerRow);
    }

    addDebugMarker_range :: (self: *MTLBuffer, marker: *NSString, range: NSRange) -> () {
        _func: (obj: *void, selector: *void, marker: *NSString, range: NSRange) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.addDebugMarker_range_, marker, range);
    }

    removeAllDebugMarkers :: (self: *MTLBuffer) -> () {
        _func: (obj: *void, selector: *void) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.removeAllDebugMarkers);
    }

    length :: (self: *MTLBuffer) -> NSUInteger {
        _func: (obj: *void, selector: *void) -> NSUInteger #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.length);
    }

}

using MTLTextureType :: enum NSUInteger {
    MTLTextureType1D :: 0;
    MTLTextureType1DArray :: 1;
    MTLTextureType2D :: 2;
    MTLTextureType2DArray :: 3;
    MTLTextureType2DMultisample :: 4;
    MTLTextureTypeCube :: 5;
    MTLTextureTypeCubeArray :: 6;
    MTLTextureType3D :: 7;
    MTLTextureType2DMultisampleArray :: 8;
    MTLTextureTypeTextureBuffer :: 9;
}

MTLSharedTextureHandle :: struct {
    nsobject: NSObject;
    _priv: *MTLSharedTextureHandlePrivate;
    device :: (self: *MTLSharedTextureHandle) -> id {
        _func: (obj: *void, selector: *void) -> id #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.device);
    }

    label :: (self: *MTLSharedTextureHandle) -> *NSString {
        _func: (obj: *void, selector: *void) -> *NSString #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.label);
    }

}

MTLSharedTextureHandlePrivate :: struct {
}

using MTLTextureUsage :: enum NSUInteger {
    MTLTextureUsageUnknown :: 0;
    MTLTextureUsageShaderRead :: 1;
    MTLTextureUsageShaderWrite :: 2;
    MTLTextureUsageRenderTarget :: 4;
    MTLTextureUsagePixelFormatView :: 16;
}

MTLTextureDescriptor :: struct {
    nsobject: NSObject;
    texture2DDescriptorWithPixelFormat_width_height_mipmapped :: (pixelFormat: MTLPixelFormat, width: NSUInteger, height: NSUInteger, mipmapped: BOOL) -> *MTLTextureDescriptor {
        _func: (obj: *void, selector: *void, pixelFormat: MTLPixelFormat, width: NSUInteger, height: NSUInteger, mipmapped: BOOL) -> *MTLTextureDescriptor #c_call;
        _func = xx objc_msgSend;
        return _func(objc_getClass("MTLTextureDescriptor"), __selectors.texture2DDescriptorWithPixelFormat_width_height_mipmapped_, pixelFormat, width, height, mipmapped);
    }

    textureCubeDescriptorWithPixelFormat_size_mipmapped :: (pixelFormat: MTLPixelFormat, size: NSUInteger, mipmapped: BOOL) -> *MTLTextureDescriptor {
        _func: (obj: *void, selector: *void, pixelFormat: MTLPixelFormat, size: NSUInteger, mipmapped: BOOL) -> *MTLTextureDescriptor #c_call;
        _func = xx objc_msgSend;
        return _func(objc_getClass("MTLTextureDescriptor"), __selectors.textureCubeDescriptorWithPixelFormat_size_mipmapped_, pixelFormat, size, mipmapped);
    }

    textureBufferDescriptorWithPixelFormat_width_resourceOptions_usage :: (pixelFormat: MTLPixelFormat, width: NSUInteger, resourceOptions: MTLResourceOptions, usage: MTLTextureUsage) -> *MTLTextureDescriptor {
        _func: (obj: *void, selector: *void, pixelFormat: MTLPixelFormat, width: NSUInteger, resourceOptions: MTLResourceOptions, usage: MTLTextureUsage) -> *MTLTextureDescriptor #c_call;
        _func = xx objc_msgSend;
        return _func(objc_getClass("MTLTextureDescriptor"), __selectors.textureBufferDescriptorWithPixelFormat_width_resourceOptions_usage_, pixelFormat, width, resourceOptions, usage);
    }

    textureType :: (self: *MTLTextureDescriptor) -> MTLTextureType {
        _func: (obj: *void, selector: *void) -> MTLTextureType #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.textureType);
    }

    setTextureType :: (self: *MTLTextureDescriptor, textureType: MTLTextureType) -> () {
        _func: (obj: *void, selector: *void, textureType: MTLTextureType) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setTextureType_, textureType);
    }

    pixelFormat :: (self: *MTLTextureDescriptor) -> MTLPixelFormat {
        _func: (obj: *void, selector: *void) -> MTLPixelFormat #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.pixelFormat);
    }

    setPixelFormat :: (self: *MTLTextureDescriptor, pixelFormat: MTLPixelFormat) -> () {
        _func: (obj: *void, selector: *void, pixelFormat: MTLPixelFormat) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setPixelFormat_, pixelFormat);
    }

    width :: (self: *MTLTextureDescriptor) -> NSUInteger {
        _func: (obj: *void, selector: *void) -> NSUInteger #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.width);
    }

    setWidth :: (self: *MTLTextureDescriptor, width: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, width: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setWidth_, width);
    }

    height :: (self: *MTLTextureDescriptor) -> NSUInteger {
        _func: (obj: *void, selector: *void) -> NSUInteger #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.height);
    }

    setHeight :: (self: *MTLTextureDescriptor, height: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, height: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setHeight_, height);
    }

    depth :: (self: *MTLTextureDescriptor) -> NSUInteger {
        _func: (obj: *void, selector: *void) -> NSUInteger #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.depth);
    }

    setDepth :: (self: *MTLTextureDescriptor, depth: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, depth: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setDepth_, depth);
    }

    mipmapLevelCount :: (self: *MTLTextureDescriptor) -> NSUInteger {
        _func: (obj: *void, selector: *void) -> NSUInteger #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.mipmapLevelCount);
    }

    setMipmapLevelCount :: (self: *MTLTextureDescriptor, mipmapLevelCount: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, mipmapLevelCount: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setMipmapLevelCount_, mipmapLevelCount);
    }

    sampleCount :: (self: *MTLTextureDescriptor) -> NSUInteger {
        _func: (obj: *void, selector: *void) -> NSUInteger #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.sampleCount);
    }

    setSampleCount :: (self: *MTLTextureDescriptor, sampleCount: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, sampleCount: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setSampleCount_, sampleCount);
    }

    arrayLength :: (self: *MTLTextureDescriptor) -> NSUInteger {
        _func: (obj: *void, selector: *void) -> NSUInteger #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.arrayLength);
    }

    setArrayLength :: (self: *MTLTextureDescriptor, arrayLength: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, arrayLength: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setArrayLength_, arrayLength);
    }

    resourceOptions :: (self: *MTLTextureDescriptor) -> MTLResourceOptions {
        _func: (obj: *void, selector: *void) -> MTLResourceOptions #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.resourceOptions);
    }

    setResourceOptions :: (self: *MTLTextureDescriptor, resourceOptions: MTLResourceOptions) -> () {
        _func: (obj: *void, selector: *void, resourceOptions: MTLResourceOptions) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setResourceOptions_, resourceOptions);
    }

    cpuCacheMode :: (self: *MTLTextureDescriptor) -> MTLCPUCacheMode {
        _func: (obj: *void, selector: *void) -> MTLCPUCacheMode #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.cpuCacheMode);
    }

    setCpuCacheMode :: (self: *MTLTextureDescriptor, cpuCacheMode: MTLCPUCacheMode) -> () {
        _func: (obj: *void, selector: *void, cpuCacheMode: MTLCPUCacheMode) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setCpuCacheMode_, cpuCacheMode);
    }

    storageMode :: (self: *MTLTextureDescriptor) -> MTLStorageMode {
        _func: (obj: *void, selector: *void) -> MTLStorageMode #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.storageMode);
    }

    setStorageMode :: (self: *MTLTextureDescriptor, storageMode: MTLStorageMode) -> () {
        _func: (obj: *void, selector: *void, storageMode: MTLStorageMode) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setStorageMode_, storageMode);
    }

    usage :: (self: *MTLTextureDescriptor) -> MTLTextureUsage {
        _func: (obj: *void, selector: *void) -> MTLTextureUsage #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.usage);
    }

    setUsage :: (self: *MTLTextureDescriptor, usage: MTLTextureUsage) -> () {
        _func: (obj: *void, selector: *void, usage: MTLTextureUsage) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setUsage_, usage);
    }

    allowGPUOptimizedContents :: (self: *MTLTextureDescriptor) -> BOOL {
        _func: (obj: *void, selector: *void) -> BOOL #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.allowGPUOptimizedContents);
    }

    setAllowGPUOptimizedContents :: (self: *MTLTextureDescriptor, allowGPUOptimizedContents: BOOL) -> () {
        _func: (obj: *void, selector: *void, allowGPUOptimizedContents: BOOL) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setAllowGPUOptimizedContents_, allowGPUOptimizedContents);
    }

}

MTLTexture :: struct {
    using MTLResource;

    getBytes_bytesPerRow_bytesPerImage_fromRegion_mipmapLevel_slice :: (self: *MTLTexture, pixelBytes: *void, bytesPerRow: NSUInteger, bytesPerImage: NSUInteger, region: MTLRegion, level: NSUInteger, slice: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, pixelBytes: *void, bytesPerRow: NSUInteger, bytesPerImage: NSUInteger, region: MTLRegion, level: NSUInteger, slice: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.getBytes_bytesPerRow_bytesPerImage_fromRegion_mipmapLevel_slice_, pixelBytes, bytesPerRow, bytesPerImage, region, level, slice);
    }

    replaceRegion_mipmapLevel_slice_withBytes_bytesPerRow_bytesPerImage :: (self: *MTLTexture, region: MTLRegion, level: NSUInteger, slice: NSUInteger, pixelBytes: *void, bytesPerRow: NSUInteger, bytesPerImage: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, region: MTLRegion, level: NSUInteger, slice: NSUInteger, pixelBytes: *void, bytesPerRow: NSUInteger, bytesPerImage: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.replaceRegion_mipmapLevel_slice_withBytes_bytesPerRow_bytesPerImage_, region, level, slice, pixelBytes, bytesPerRow, bytesPerImage);
    }

    getBytes_bytesPerRow_fromRegion_mipmapLevel :: (self: *MTLTexture, pixelBytes: *void, bytesPerRow: NSUInteger, region: MTLRegion, level: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, pixelBytes: *void, bytesPerRow: NSUInteger, region: MTLRegion, level: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.getBytes_bytesPerRow_fromRegion_mipmapLevel_, pixelBytes, bytesPerRow, region, level);
    }

    replaceRegion_mipmapLevel_withBytes_bytesPerRow :: (self: *MTLTexture, region: MTLRegion, level: NSUInteger, pixelBytes: *void, bytesPerRow: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, region: MTLRegion, level: NSUInteger, pixelBytes: *void, bytesPerRow: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.replaceRegion_mipmapLevel_withBytes_bytesPerRow_, region, level, pixelBytes, bytesPerRow);
    }

    newTextureViewWithPixelFormat :: (self: *MTLTexture, pixelFormat: MTLPixelFormat) -> id {
        _func: (obj: *void, selector: *void, pixelFormat: MTLPixelFormat) -> id #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.newTextureViewWithPixelFormat_, pixelFormat);
    }

    newTextureViewWithPixelFormat_textureType_levels_slices :: (self: *MTLTexture, pixelFormat: MTLPixelFormat, textureType: MTLTextureType, levelRange: NSRange, sliceRange: NSRange) -> id {
        _func: (obj: *void, selector: *void, pixelFormat: MTLPixelFormat, textureType: MTLTextureType, levelRange: NSRange, sliceRange: NSRange) -> id #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.newTextureViewWithPixelFormat_textureType_levels_slices_, pixelFormat, textureType, levelRange, sliceRange);
    }

    newSharedTextureHandle :: (self: *MTLTexture) -> *MTLSharedTextureHandle {
        _func: (obj: *void, selector: *void) -> *MTLSharedTextureHandle #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.newSharedTextureHandle);
    }

    rootResource :: (self: *MTLTexture) -> id {
        _func: (obj: *void, selector: *void) -> id #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.rootResource);
    }

    parentTexture :: (self: *MTLTexture) -> id {
        _func: (obj: *void, selector: *void) -> id #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.parentTexture);
    }

    parentRelativeLevel :: (self: *MTLTexture) -> NSUInteger {
        _func: (obj: *void, selector: *void) -> NSUInteger #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.parentRelativeLevel);
    }

    parentRelativeSlice :: (self: *MTLTexture) -> NSUInteger {
        _func: (obj: *void, selector: *void) -> NSUInteger #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.parentRelativeSlice);
    }

    buffer :: (self: *MTLTexture) -> id {
        _func: (obj: *void, selector: *void) -> id #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.buffer);
    }

    bufferOffset :: (self: *MTLTexture) -> NSUInteger {
        _func: (obj: *void, selector: *void) -> NSUInteger #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.bufferOffset);
    }

    bufferBytesPerRow :: (self: *MTLTexture) -> NSUInteger {
        _func: (obj: *void, selector: *void) -> NSUInteger #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.bufferBytesPerRow);
    }

    iosurface :: (self: *MTLTexture) -> IOSurfaceRef {
        _func: (obj: *void, selector: *void) -> IOSurfaceRef #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.iosurface);
    }

    iosurfacePlane :: (self: *MTLTexture) -> NSUInteger {
        _func: (obj: *void, selector: *void) -> NSUInteger #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.iosurfacePlane);
    }

    textureType :: (self: *MTLTexture) -> MTLTextureType {
        _func: (obj: *void, selector: *void) -> MTLTextureType #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.textureType);
    }

    pixelFormat :: (self: *MTLTexture) -> MTLPixelFormat {
        _func: (obj: *void, selector: *void) -> MTLPixelFormat #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.pixelFormat);
    }

    width :: (self: *MTLTexture) -> NSUInteger {
        _func: (obj: *void, selector: *void) -> NSUInteger #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.width);
    }

    height :: (self: *MTLTexture) -> NSUInteger {
        _func: (obj: *void, selector: *void) -> NSUInteger #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.height);
    }

    depth :: (self: *MTLTexture) -> NSUInteger {
        _func: (obj: *void, selector: *void) -> NSUInteger #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.depth);
    }

    mipmapLevelCount :: (self: *MTLTexture) -> NSUInteger {
        _func: (obj: *void, selector: *void) -> NSUInteger #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.mipmapLevelCount);
    }

    sampleCount :: (self: *MTLTexture) -> NSUInteger {
        _func: (obj: *void, selector: *void) -> NSUInteger #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.sampleCount);
    }

    arrayLength :: (self: *MTLTexture) -> NSUInteger {
        _func: (obj: *void, selector: *void) -> NSUInteger #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.arrayLength);
    }

    usage :: (self: *MTLTexture) -> MTLTextureUsage {
        _func: (obj: *void, selector: *void) -> MTLTextureUsage #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.usage);
    }

    isShareable :: (self: *MTLTexture) -> BOOL {
        _func: (obj: *void, selector: *void) -> BOOL #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.isShareable);
    }

    isFramebufferOnly :: (self: *MTLTexture) -> BOOL {
        _func: (obj: *void, selector: *void) -> BOOL #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.isFramebufferOnly);
    }

    allowGPUOptimizedContents :: (self: *MTLTexture) -> BOOL {
        _func: (obj: *void, selector: *void) -> BOOL #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.allowGPUOptimizedContents);
    }

}

using MTLDataType :: enum NSUInteger {
    MTLDataTypeNone :: 0;
    MTLDataTypeStruct :: 1;
    MTLDataTypeArray :: 2;
    MTLDataTypeFloat :: 3;
    MTLDataTypeFloat2 :: 4;
    MTLDataTypeFloat3 :: 5;
    MTLDataTypeFloat4 :: 6;
    MTLDataTypeFloat2x2 :: 7;
    MTLDataTypeFloat2x3 :: 8;
    MTLDataTypeFloat2x4 :: 9;
    MTLDataTypeFloat3x2 :: 10;
    MTLDataTypeFloat3x3 :: 11;
    MTLDataTypeFloat3x4 :: 12;
    MTLDataTypeFloat4x2 :: 13;
    MTLDataTypeFloat4x3 :: 14;
    MTLDataTypeFloat4x4 :: 15;
    MTLDataTypeHalf :: 16;
    MTLDataTypeHalf2 :: 17;
    MTLDataTypeHalf3 :: 18;
    MTLDataTypeHalf4 :: 19;
    MTLDataTypeHalf2x2 :: 20;
    MTLDataTypeHalf2x3 :: 21;
    MTLDataTypeHalf2x4 :: 22;
    MTLDataTypeHalf3x2 :: 23;
    MTLDataTypeHalf3x3 :: 24;
    MTLDataTypeHalf3x4 :: 25;
    MTLDataTypeHalf4x2 :: 26;
    MTLDataTypeHalf4x3 :: 27;
    MTLDataTypeHalf4x4 :: 28;
    MTLDataTypeInt :: 29;
    MTLDataTypeInt2 :: 30;
    MTLDataTypeInt3 :: 31;
    MTLDataTypeInt4 :: 32;
    MTLDataTypeUInt :: 33;
    MTLDataTypeUInt2 :: 34;
    MTLDataTypeUInt3 :: 35;
    MTLDataTypeUInt4 :: 36;
    MTLDataTypeShort :: 37;
    MTLDataTypeShort2 :: 38;
    MTLDataTypeShort3 :: 39;
    MTLDataTypeShort4 :: 40;
    MTLDataTypeUShort :: 41;
    MTLDataTypeUShort2 :: 42;
    MTLDataTypeUShort3 :: 43;
    MTLDataTypeUShort4 :: 44;
    MTLDataTypeChar :: 45;
    MTLDataTypeChar2 :: 46;
    MTLDataTypeChar3 :: 47;
    MTLDataTypeChar4 :: 48;
    MTLDataTypeUChar :: 49;
    MTLDataTypeUChar2 :: 50;
    MTLDataTypeUChar3 :: 51;
    MTLDataTypeUChar4 :: 52;
    MTLDataTypeBool :: 53;
    MTLDataTypeBool2 :: 54;
    MTLDataTypeBool3 :: 55;
    MTLDataTypeBool4 :: 56;
    MTLDataTypeTexture :: 58;
    MTLDataTypeSampler :: 59;
    MTLDataTypePointer :: 60;
    MTLDataTypeRenderPipeline :: 78;
    MTLDataTypeIndirectCommandBuffer :: 80;
}



using MTLArgumentType :: enum NSUInteger {
    MTLArgumentTypeBuffer :: 0;
    MTLArgumentTypeThreadgroupMemory :: 1;
    MTLArgumentTypeTexture :: 2;
    MTLArgumentTypeSampler :: 3;
}

using MTLArgumentAccess :: enum NSUInteger {
    MTLArgumentAccessReadOnly :: 0;
    MTLArgumentAccessReadWrite :: 1;
    MTLArgumentAccessWriteOnly :: 2;
}

MTLType :: struct {
    nsobject: NSObject;
    dataType :: (self: *MTLType) -> MTLDataType {
        _func: (obj: *void, selector: *void) -> MTLDataType #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.dataType);
    }

}

MTLStructMember :: struct {
    nsobject: NSObject;
    structType :: (self: *MTLStructMember) -> *MTLStructType {
        _func: (obj: *void, selector: *void) -> *MTLStructType #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.structType);
    }

    arrayType :: (self: *MTLStructMember) -> *MTLArrayType {
        _func: (obj: *void, selector: *void) -> *MTLArrayType #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.arrayType);
    }

    textureReferenceType :: (self: *MTLStructMember) -> *MTLTextureReferenceType {
        _func: (obj: *void, selector: *void) -> *MTLTextureReferenceType #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.textureReferenceType);
    }

    pointerType :: (self: *MTLStructMember) -> *MTLPointerType {
        _func: (obj: *void, selector: *void) -> *MTLPointerType #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.pointerType);
    }

    name :: (self: *MTLStructMember) -> *NSString {
        _func: (obj: *void, selector: *void) -> *NSString #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.name);
    }

    offset :: (self: *MTLStructMember) -> NSUInteger {
        _func: (obj: *void, selector: *void) -> NSUInteger #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.offset);
    }

    dataType :: (self: *MTLStructMember) -> MTLDataType {
        _func: (obj: *void, selector: *void) -> MTLDataType #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.dataType);
    }

    argumentIndex :: (self: *MTLStructMember) -> NSUInteger {
        _func: (obj: *void, selector: *void) -> NSUInteger #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.argumentIndex);
    }

}

MTLStructType :: struct {
    mtltype: MTLType;
    memberByName :: (self: *MTLStructType, name: *NSString) -> *MTLStructMember {
        _func: (obj: *void, selector: *void, name: *NSString) -> *MTLStructMember #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.memberByName_, name);
    }

    members :: (self: *MTLStructType) -> *NSArray(*MTLStructMember) {
        _func: (obj: *void, selector: *void) -> *NSArray(*MTLStructMember) #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.members);
    }

}

MTLArrayType :: struct {
    mtltype: MTLType;
    elementStructType :: (self: *MTLArrayType) -> *MTLStructType {
        _func: (obj: *void, selector: *void) -> *MTLStructType #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.elementStructType);
    }

    elementArrayType :: (self: *MTLArrayType) -> *MTLArrayType {
        _func: (obj: *void, selector: *void) -> *MTLArrayType #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.elementArrayType);
    }

    elementTextureReferenceType :: (self: *MTLArrayType) -> *MTLTextureReferenceType {
        _func: (obj: *void, selector: *void) -> *MTLTextureReferenceType #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.elementTextureReferenceType);
    }

    elementPointerType :: (self: *MTLArrayType) -> *MTLPointerType {
        _func: (obj: *void, selector: *void) -> *MTLPointerType #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.elementPointerType);
    }

    elementType :: (self: *MTLArrayType) -> MTLDataType {
        _func: (obj: *void, selector: *void) -> MTLDataType #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.elementType);
    }

    arrayLength :: (self: *MTLArrayType) -> NSUInteger {
        _func: (obj: *void, selector: *void) -> NSUInteger #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.arrayLength);
    }

    stride :: (self: *MTLArrayType) -> NSUInteger {
        _func: (obj: *void, selector: *void) -> NSUInteger #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.stride);
    }

    argumentIndexStride :: (self: *MTLArrayType) -> NSUInteger {
        _func: (obj: *void, selector: *void) -> NSUInteger #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.argumentIndexStride);
    }

}

MTLPointerType :: struct {
    mtltype: MTLType;
    elementStructType :: (self: *MTLPointerType) -> *MTLStructType {
        _func: (obj: *void, selector: *void) -> *MTLStructType #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.elementStructType);
    }

    elementArrayType :: (self: *MTLPointerType) -> *MTLArrayType {
        _func: (obj: *void, selector: *void) -> *MTLArrayType #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.elementArrayType);
    }

    elementType :: (self: *MTLPointerType) -> MTLDataType {
        _func: (obj: *void, selector: *void) -> MTLDataType #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.elementType);
    }

    access :: (self: *MTLPointerType) -> MTLArgumentAccess {
        _func: (obj: *void, selector: *void) -> MTLArgumentAccess #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.access);
    }

    alignment :: (self: *MTLPointerType) -> NSUInteger {
        _func: (obj: *void, selector: *void) -> NSUInteger #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.alignment);
    }

    dataSize :: (self: *MTLPointerType) -> NSUInteger {
        _func: (obj: *void, selector: *void) -> NSUInteger #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.dataSize);
    }

    elementIsArgumentBuffer :: (self: *MTLPointerType) -> BOOL {
        _func: (obj: *void, selector: *void) -> BOOL #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.elementIsArgumentBuffer);
    }

}

MTLTextureReferenceType :: struct {
    mtltype: MTLType;
    textureDataType :: (self: *MTLTextureReferenceType) -> MTLDataType {
        _func: (obj: *void, selector: *void) -> MTLDataType #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.textureDataType);
    }

    textureType :: (self: *MTLTextureReferenceType) -> MTLTextureType {
        _func: (obj: *void, selector: *void) -> MTLTextureType #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.textureType);
    }

    access :: (self: *MTLTextureReferenceType) -> MTLArgumentAccess {
        _func: (obj: *void, selector: *void) -> MTLArgumentAccess #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.access);
    }

    isDepthTexture :: (self: *MTLTextureReferenceType) -> BOOL {
        _func: (obj: *void, selector: *void) -> BOOL #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.isDepthTexture);
    }

}

MTLArgument :: struct {
    nsobject: NSObject;
    name :: (self: *MTLArgument) -> *NSString {
        _func: (obj: *void, selector: *void) -> *NSString #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.name);
    }

    type :: (self: *MTLArgument) -> MTLArgumentType {
        _func: (obj: *void, selector: *void) -> MTLArgumentType #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.type);
    }

    access :: (self: *MTLArgument) -> MTLArgumentAccess {
        _func: (obj: *void, selector: *void) -> MTLArgumentAccess #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.access);
    }

    index :: (self: *MTLArgument) -> NSUInteger {
        _func: (obj: *void, selector: *void) -> NSUInteger #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.index);
    }

    isActive :: (self: *MTLArgument) -> BOOL {
        _func: (obj: *void, selector: *void) -> BOOL #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.isActive);
    }

    bufferAlignment :: (self: *MTLArgument) -> NSUInteger {
        _func: (obj: *void, selector: *void) -> NSUInteger #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.bufferAlignment);
    }

    bufferDataSize :: (self: *MTLArgument) -> NSUInteger {
        _func: (obj: *void, selector: *void) -> NSUInteger #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.bufferDataSize);
    }

    bufferDataType :: (self: *MTLArgument) -> MTLDataType {
        _func: (obj: *void, selector: *void) -> MTLDataType #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.bufferDataType);
    }

    bufferStructType :: (self: *MTLArgument) -> *MTLStructType {
        _func: (obj: *void, selector: *void) -> *MTLStructType #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.bufferStructType);
    }

    bufferPointerType :: (self: *MTLArgument) -> *MTLPointerType {
        _func: (obj: *void, selector: *void) -> *MTLPointerType #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.bufferPointerType);
    }

    threadgroupMemoryAlignment :: (self: *MTLArgument) -> NSUInteger {
        _func: (obj: *void, selector: *void) -> NSUInteger #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.threadgroupMemoryAlignment);
    }

    threadgroupMemoryDataSize :: (self: *MTLArgument) -> NSUInteger {
        _func: (obj: *void, selector: *void) -> NSUInteger #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.threadgroupMemoryDataSize);
    }

    textureType :: (self: *MTLArgument) -> MTLTextureType {
        _func: (obj: *void, selector: *void) -> MTLTextureType #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.textureType);
    }

    textureDataType :: (self: *MTLArgument) -> MTLDataType {
        _func: (obj: *void, selector: *void) -> MTLDataType #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.textureDataType);
    }

    isDepthTexture :: (self: *MTLArgument) -> BOOL {
        _func: (obj: *void, selector: *void) -> BOOL #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.isDepthTexture);
    }

    arrayLength :: (self: *MTLArgument) -> NSUInteger {
        _func: (obj: *void, selector: *void) -> NSUInteger #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.arrayLength);
    }

}

MTLAutoreleasedArgument :: *MTLArgument;

using MTLPatchType :: enum NSUInteger {
    MTLPatchTypeNone :: 0;
    MTLPatchTypeTriangle :: 1;
    MTLPatchTypeQuad :: 2;
}

MTLVertexAttribute :: struct {
    nsobject: NSObject;
    name :: (self: *MTLVertexAttribute) -> *NSString {
        _func: (obj: *void, selector: *void) -> *NSString #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.name);
    }

    attributeIndex :: (self: *MTLVertexAttribute) -> NSUInteger {
        _func: (obj: *void, selector: *void) -> NSUInteger #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.attributeIndex);
    }

    attributeType :: (self: *MTLVertexAttribute) -> MTLDataType {
        _func: (obj: *void, selector: *void) -> MTLDataType #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.attributeType);
    }

    isActive :: (self: *MTLVertexAttribute) -> BOOL {
        _func: (obj: *void, selector: *void) -> BOOL #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.isActive);
    }

    isPatchData :: (self: *MTLVertexAttribute) -> BOOL {
        _func: (obj: *void, selector: *void) -> BOOL #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.isPatchData);
    }

    isPatchControlPointData :: (self: *MTLVertexAttribute) -> BOOL {
        _func: (obj: *void, selector: *void) -> BOOL #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.isPatchControlPointData);
    }

}

MTLAttribute :: struct {
    nsobject: NSObject;
    name :: (self: *MTLAttribute) -> *NSString {
        _func: (obj: *void, selector: *void) -> *NSString #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.name);
    }

    attributeIndex :: (self: *MTLAttribute) -> NSUInteger {
        _func: (obj: *void, selector: *void) -> NSUInteger #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.attributeIndex);
    }

    attributeType :: (self: *MTLAttribute) -> MTLDataType {
        _func: (obj: *void, selector: *void) -> MTLDataType #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.attributeType);
    }

    isActive :: (self: *MTLAttribute) -> BOOL {
        _func: (obj: *void, selector: *void) -> BOOL #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.isActive);
    }

    isPatchData :: (self: *MTLAttribute) -> BOOL {
        _func: (obj: *void, selector: *void) -> BOOL #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.isPatchData);
    }

    isPatchControlPointData :: (self: *MTLAttribute) -> BOOL {
        _func: (obj: *void, selector: *void) -> BOOL #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.isPatchControlPointData);
    }

}

using MTLFunctionType :: enum NSUInteger {
    MTLFunctionTypeVertex :: 1;
    MTLFunctionTypeFragment :: 2;
    MTLFunctionTypeKernel :: 3;
}



MTLFunctionConstant :: struct {
    nsobject: NSObject;
    name :: (self: *MTLFunctionConstant) -> *NSString {
        _func: (obj: *void, selector: *void) -> *NSString #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.name);
    }

    type :: (self: *MTLFunctionConstant) -> MTLDataType {
        _func: (obj: *void, selector: *void) -> MTLDataType #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.type);
    }

    index :: (self: *MTLFunctionConstant) -> NSUInteger {
        _func: (obj: *void, selector: *void) -> NSUInteger #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.index);
    }

    required :: (self: *MTLFunctionConstant) -> BOOL {
        _func: (obj: *void, selector: *void) -> BOOL #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.required);
    }

}

MTLFunction :: struct {
    newArgumentEncoderWithBufferIndex :: (self: *MTLFunction, bufferIndex: NSUInteger) -> id {
        _func: (obj: *void, selector: *void, bufferIndex: NSUInteger) -> id #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.newArgumentEncoderWithBufferIndex_, bufferIndex);
    }

    newArgumentEncoderWithBufferIndex_reflection :: (self: *MTLFunction, bufferIndex: NSUInteger, reflection: **MTLArgument) -> id {
        _func: (obj: *void, selector: *void, bufferIndex: NSUInteger, reflection: **MTLArgument) -> id #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.newArgumentEncoderWithBufferIndex_reflection_, bufferIndex, reflection);
    }

    label :: (self: *MTLFunction) -> *NSString {
        _func: (obj: *void, selector: *void) -> *NSString #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.label);
    }

    setLabel :: (self: *MTLFunction, label: *NSString) -> () {
        _func: (obj: *void, selector: *void, label: *NSString) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setLabel_, label);
    }

    device :: (self: *MTLFunction) -> id {
        _func: (obj: *void, selector: *void) -> id #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.device);
    }

    functionType :: (self: *MTLFunction) -> MTLFunctionType {
        _func: (obj: *void, selector: *void) -> MTLFunctionType #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.functionType);
    }

    patchType :: (self: *MTLFunction) -> MTLPatchType {
        _func: (obj: *void, selector: *void) -> MTLPatchType #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.patchType);
    }

    patchControlPointCount :: (self: *MTLFunction) -> NSInteger {
        _func: (obj: *void, selector: *void) -> NSInteger #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.patchControlPointCount);
    }

    vertexAttributes :: (self: *MTLFunction) -> *NSArray(*MTLVertexAttribute) {
        _func: (obj: *void, selector: *void) -> *NSArray(*MTLVertexAttribute) #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.vertexAttributes);
    }

    stageInputAttributes :: (self: *MTLFunction) -> *NSArray(*MTLAttribute) {
        _func: (obj: *void, selector: *void) -> *NSArray(*MTLAttribute) #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.stageInputAttributes);
    }

    name :: (self: *MTLFunction) -> *NSString {
        _func: (obj: *void, selector: *void) -> *NSString #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.name);
    }

    functionConstantsDictionary :: (self: *MTLFunction) -> *NSDictionary {
        _func: (obj: *void, selector: *void) -> *NSDictionary #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.functionConstantsDictionary);
    }

}

using MTLLanguageVersion :: enum NSUInteger {
    MTLLanguageVersion1_0 :: 65536;
    MTLLanguageVersion1_1 :: 65537;
    MTLLanguageVersion1_2 :: 65538;
    MTLLanguageVersion2_0 :: 131072;
    MTLLanguageVersion2_1 :: 131073;
    MTLLanguageVersion2_2 :: (2 << 16) + 2;
    MTLLanguageVersion2_3 :: (2 << 16) + 3;
    MTLLanguageVersion2_4 :: (2 << 16) + 4;
    MTLLanguageVersion3_0 :: (3 << 16) + 0;
    MTLLanguageVersion4_0 :: (4 << 16) + 0;
}



MTLCompileOptions :: struct {
    nsobject: NSObject;
    preprocessorMacros :: (self: *MTLCompileOptions) -> *NSDictionary {
        _func: (obj: *void, selector: *void) -> *NSDictionary #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.preprocessorMacros);
    }

    setPreprocessorMacros :: (self: *MTLCompileOptions, preprocessorMacros: *NSDictionary) -> () {
        _func: (obj: *void, selector: *void, preprocessorMacros: *NSDictionary) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setPreprocessorMacros_, preprocessorMacros);
    }

    fastMathEnabled :: (self: *MTLCompileOptions) -> BOOL {
        _func: (obj: *void, selector: *void) -> BOOL #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.fastMathEnabled);
    }

    setFastMathEnabled :: (self: *MTLCompileOptions, fastMathEnabled: BOOL) -> () {
        _func: (obj: *void, selector: *void, fastMathEnabled: BOOL) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setFastMathEnabled_, fastMathEnabled);
    }

    languageVersion :: (self: *MTLCompileOptions) -> MTLLanguageVersion {
        _func: (obj: *void, selector: *void) -> MTLLanguageVersion #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.languageVersion);
    }

    setLanguageVersion :: (self: *MTLCompileOptions, languageVersion: MTLLanguageVersion) -> () {
        _func: (obj: *void, selector: *void, languageVersion: MTLLanguageVersion) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setLanguageVersion_, languageVersion);
    }

}

MTLLibraryErrorDomain: *NSString;

using MTLLibraryError :: enum NSUInteger {
    MTLLibraryErrorUnsupported :: 1;
    MTLLibraryErrorInternal :: 2;
    MTLLibraryErrorCompileFailure :: 3;
    MTLLibraryErrorCompileWarning :: 4;
    MTLLibraryErrorFunctionNotFound :: 5;
    MTLLibraryErrorFileNotFound :: 6;
}



MTLLibrary :: struct {
    newFunctionWithName :: (self: *MTLLibrary, functionName: *NSString) -> id {
        _func: (obj: *void, selector: *void, functionName: *NSString) -> id #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.newFunctionWithName_, functionName);
    }

    newFunctionWithName_constantValues_error :: (self: *MTLLibrary, name: *NSString, constantValues: *MTLFunctionConstantValues, error: **NSError) -> id {
        _func: (obj: *void, selector: *void, name: *NSString, constantValues: *MTLFunctionConstantValues, error: **NSError) -> id #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.newFunctionWithName_constantValues_error_, name, constantValues, error);
    }

    label :: (self: *MTLLibrary) -> *NSString {
        _func: (obj: *void, selector: *void) -> *NSString #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.label);
    }

    setLabel :: (self: *MTLLibrary, label: *NSString) -> () {
        _func: (obj: *void, selector: *void, label: *NSString) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setLabel_, label);
    }

    device :: (self: *MTLLibrary) -> id {
        _func: (obj: *void, selector: *void) -> id #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.device);
    }

    functionNames :: (self: *MTLLibrary) -> *NSArray(*NSString) {
        _func: (obj: *void, selector: *void) -> *NSArray(*NSString) #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.functionNames);
    }

}

MTLCreateSystemDefaultDevice :: () -> id #foreign Metal;

MTLCopyAllDevices :: () -> *NSArray(id) #foreign Metal;

MTLDeviceNotificationName :: *NSString;

MTLDeviceWasAddedNotification: MTLDeviceNotificationName;

MTLDeviceRemovalRequestedNotification: MTLDeviceNotificationName;

MTLDeviceWasRemovedNotification: MTLDeviceNotificationName;

MTLRemoveDeviceObserver :: (observer: id) -> () #foreign Metal;

using MTLFeatureSet :: enum NSUInteger {
    MTLFeatureSet_iOS_GPUFamily1_v1 :: 0;
    MTLFeatureSet_iOS_GPUFamily2_v1 :: 1;
    MTLFeatureSet_iOS_GPUFamily1_v2 :: 2;
    MTLFeatureSet_iOS_GPUFamily2_v2 :: 3;
    MTLFeatureSet_iOS_GPUFamily3_v1 :: 4;
    MTLFeatureSet_iOS_GPUFamily1_v3 :: 5;
    MTLFeatureSet_iOS_GPUFamily2_v3 :: 6;
    MTLFeatureSet_iOS_GPUFamily3_v2 :: 7;
    MTLFeatureSet_iOS_GPUFamily1_v4 :: 8;
    MTLFeatureSet_iOS_GPUFamily2_v4 :: 9;
    MTLFeatureSet_iOS_GPUFamily3_v3 :: 10;
    MTLFeatureSet_iOS_GPUFamily4_v1 :: 11;
    MTLFeatureSet_iOS_GPUFamily1_v5 :: 12;
    MTLFeatureSet_iOS_GPUFamily2_v5 :: 13;
    MTLFeatureSet_iOS_GPUFamily3_v4 :: 14;
    MTLFeatureSet_iOS_GPUFamily4_v2 :: 15;
    MTLFeatureSet_macOS_GPUFamily1_v1 :: 10000;
    MTLFeatureSet_OSX_GPUFamily1_v1 :: 10000;
    MTLFeatureSet_macOS_GPUFamily1_v2 :: 10001;
    MTLFeatureSet_OSX_GPUFamily1_v2 :: 10001;
    MTLFeatureSet_macOS_ReadWriteTextureTier2 :: 10002;
    MTLFeatureSet_OSX_ReadWriteTextureTier2 :: 10002;
    MTLFeatureSet_macOS_GPUFamily1_v3 :: 10003;
    MTLFeatureSet_macOS_GPUFamily1_v4 :: 10004;
    MTLFeatureSet_macOS_GPUFamily2_v1 :: 10005;
    MTLFeatureSet_tvOS_GPUFamily1_v1 :: 30000;
    MTLFeatureSet_TVOS_GPUFamily1_v1 :: 30000;
    MTLFeatureSet_tvOS_GPUFamily1_v2 :: 30001;
    MTLFeatureSet_tvOS_GPUFamily1_v3 :: 30002;
    MTLFeatureSet_tvOS_GPUFamily1_v4 :: 30004;
}


MTLGPUFamily :: enum NSUInteger {
    Apple1  :: 1001;
    Apple2  :: 1002;
    Apple3  :: 1003;
    Apple4  :: 1004;
    Apple5  :: 1005;
    Apple6  :: 1006;
    Apple7  :: 1007;
    Apple8  :: 1008;
    Apple9  :: 1009;
    Mac2    :: 2002;
    Common1 :: 3001;
    Common2 :: 3002;
    Common3 :: 3003;
    Metal3  :: 5001;
}



using MTLPipelineOption :: enum NSUInteger {
    MTLPipelineOptionNone :: 0;
    MTLPipelineOptionArgumentInfo :: 1;
    MTLPipelineOptionBufferTypeInfo :: 2;
}



using MTLReadWriteTextureTier :: enum NSUInteger {
    MTLReadWriteTextureTierNone :: 0;
    MTLReadWriteTextureTier1 :: 1;
    MTLReadWriteTextureTier2 :: 2;
}



using MTLArgumentBuffersTier :: enum NSUInteger {
    MTLArgumentBuffersTier1 :: 0;
    MTLArgumentBuffersTier2 :: 1;
}



MTLSizeAndAlign :: struct {
    size: NSUInteger;
    align: NSUInteger;
}

MTLAutoreleasedRenderPipelineReflection :: *MTLRenderPipelineReflection;

MTLAutoreleasedComputePipelineReflection :: *MTLComputePipelineReflection;

MTLArgumentDescriptor :: struct {
    nsobject: NSObject;
    argumentDescriptor :: () -> *MTLArgumentDescriptor {
        _func: (obj: *void, selector: *void) -> *MTLArgumentDescriptor #c_call;
        _func = xx objc_msgSend;
        return _func(objc_getClass("MTLArgumentDescriptor"), __selectors.argumentDescriptor);
    }

    dataType :: (self: *MTLArgumentDescriptor) -> MTLDataType {
        _func: (obj: *void, selector: *void) -> MTLDataType #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.dataType);
    }

    setDataType :: (self: *MTLArgumentDescriptor, dataType: MTLDataType) -> () {
        _func: (obj: *void, selector: *void, dataType: MTLDataType) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setDataType_, dataType);
    }

    index :: (self: *MTLArgumentDescriptor) -> NSUInteger {
        _func: (obj: *void, selector: *void) -> NSUInteger #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.index);
    }

    setIndex :: (self: *MTLArgumentDescriptor, index: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, index: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setIndex_, index);
    }

    arrayLength :: (self: *MTLArgumentDescriptor) -> NSUInteger {
        _func: (obj: *void, selector: *void) -> NSUInteger #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.arrayLength);
    }

    setArrayLength :: (self: *MTLArgumentDescriptor, arrayLength: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, arrayLength: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setArrayLength_, arrayLength);
    }

    access :: (self: *MTLArgumentDescriptor) -> MTLArgumentAccess {
        _func: (obj: *void, selector: *void) -> MTLArgumentAccess #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.access);
    }

    setAccess :: (self: *MTLArgumentDescriptor, access: MTLArgumentAccess) -> () {
        _func: (obj: *void, selector: *void, access: MTLArgumentAccess) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setAccess_, access);
    }

    textureType :: (self: *MTLArgumentDescriptor) -> MTLTextureType {
        _func: (obj: *void, selector: *void) -> MTLTextureType #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.textureType);
    }

    setTextureType :: (self: *MTLArgumentDescriptor, textureType: MTLTextureType) -> () {
        _func: (obj: *void, selector: *void, textureType: MTLTextureType) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setTextureType_, textureType);
    }

    constantBlockAlignment :: (self: *MTLArgumentDescriptor) -> NSUInteger {
        _func: (obj: *void, selector: *void) -> NSUInteger #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.constantBlockAlignment);
    }

    setConstantBlockAlignment :: (self: *MTLArgumentDescriptor, constantBlockAlignment: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, constantBlockAlignment: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setConstantBlockAlignment_, constantBlockAlignment);
    }

}

MTLDevice :: struct {
    newCommandQueue :: (self: *MTLDevice) -> *MTLCommandQueue {
        _func: (obj: *void, selector: *void) -> *MTLCommandQueue #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.newCommandQueue);
    }

    newCommandQueueWithMaxCommandBufferCount :: (self: *MTLDevice, maxCommandBufferCount: NSUInteger) -> *MTLCommandQueue {
        _func: (obj: *void, selector: *void, maxCommandBufferCount: NSUInteger) -> *MTLCommandQueue #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.newCommandQueueWithMaxCommandBufferCount_, maxCommandBufferCount);
    }

    heapTextureSizeAndAlignWithDescriptor :: (self: *MTLDevice, desc: *MTLTextureDescriptor) -> MTLSizeAndAlign {
        _func: (obj: *void, selector: *void, desc: *MTLTextureDescriptor) -> MTLSizeAndAlign #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.heapTextureSizeAndAlignWithDescriptor_, desc);
    }

    heapBufferSizeAndAlignWithLength_options :: (self: *MTLDevice, length: NSUInteger, options: MTLResourceOptions) -> MTLSizeAndAlign {
        _func: (obj: *void, selector: *void, length: NSUInteger, options: MTLResourceOptions) -> MTLSizeAndAlign #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.heapBufferSizeAndAlignWithLength_options_, length, options);
    }

    newHeapWithDescriptor :: (self: *MTLDevice, descriptor: *MTLHeapDescriptor) -> id {
        _func: (obj: *void, selector: *void, descriptor: *MTLHeapDescriptor) -> id #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.newHeapWithDescriptor_, descriptor);
    }

    newBufferWithLength_options :: (self: *MTLDevice, length: NSUInteger, options: MTLResourceOptions) -> *MTLBuffer {
        _func: (obj: *void, selector: *void, length: NSUInteger, options: MTLResourceOptions) -> *MTLBuffer #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.newBufferWithLength_options_, length, options);
    }

    newBufferWithBytes_length_options :: (self: *MTLDevice, pointer: *void, length: NSUInteger, options: MTLResourceOptions) -> *MTLBuffer {
        _func: (obj: *void, selector: *void, pointer: *void, length: NSUInteger, options: MTLResourceOptions) -> *MTLBuffer #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.newBufferWithBytes_length_options_, pointer, length, options);
    }

    newDepthStencilStateWithDescriptor :: (self: *MTLDevice, descriptor: *MTLDepthStencilDescriptor) -> id {
        _func: (obj: *void, selector: *void, descriptor: *MTLDepthStencilDescriptor) -> id #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.newDepthStencilStateWithDescriptor_, descriptor);
    }

    newTextureWithDescriptor :: (self: *MTLDevice, descriptor: *MTLTextureDescriptor) -> id {
        _func: (obj: *void, selector: *void, descriptor: *MTLTextureDescriptor) -> id #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.newTextureWithDescriptor_, descriptor);
    }

    newTextureWithDescriptor_iosurface_plane :: (self: *MTLDevice, descriptor: *MTLTextureDescriptor, iosurface: IOSurfaceRef, plane: NSUInteger) -> id {
        _func: (obj: *void, selector: *void, descriptor: *MTLTextureDescriptor, iosurface: IOSurfaceRef, plane: NSUInteger) -> id #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.newTextureWithDescriptor_iosurface_plane_, descriptor, iosurface, plane);
    }

    newSharedTextureWithDescriptor :: (self: *MTLDevice, descriptor: *MTLTextureDescriptor) -> id {
        _func: (obj: *void, selector: *void, descriptor: *MTLTextureDescriptor) -> id #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.newSharedTextureWithDescriptor_, descriptor);
    }

    newSharedTextureWithHandle :: (self: *MTLDevice, sharedHandle: *MTLSharedTextureHandle) -> id {
        _func: (obj: *void, selector: *void, sharedHandle: *MTLSharedTextureHandle) -> id #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.newSharedTextureWithHandle_, sharedHandle);
    }

    newSamplerStateWithDescriptor :: (self: *MTLDevice, descriptor: *MTLSamplerDescriptor) -> id {
        _func: (obj: *void, selector: *void, descriptor: *MTLSamplerDescriptor) -> id #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.newSamplerStateWithDescriptor_, descriptor);
    }

    newDefaultLibrary :: (self: *MTLDevice) -> *MTLLibrary {
        _func: (obj: *void, selector: *void) -> *MTLLibrary #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.newDefaultLibrary);
    }

    newDefaultLibraryWithBundle_error :: (self: *MTLDevice, bundle: *NSBundle, error: **NSError) -> *MTLLibrary {
        _func: (obj: *void, selector: *void, bundle: *NSBundle, error: **NSError) -> *MTLLibrary #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.newDefaultLibraryWithBundle_error_, bundle, error);
    }

    newLibraryWithFile_error :: (self: *MTLDevice, filepath: *NSString, error: **NSError) -> *MTLLibrary {
        _func: (obj: *void, selector: *void, filepath: *NSString, error: **NSError) -> *MTLLibrary #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.newLibraryWithFile_error_, filepath, error);
    }

    newLibraryWithURL_error :: (self: *MTLDevice, url: *NSURL, error: **NSError) -> *MTLLibrary {
        _func: (obj: *void, selector: *void, url: *NSURL, error: **NSError) -> *MTLLibrary #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.newLibraryWithURL_error_, url, error);
    }

    newLibraryWithData_error :: (self: *MTLDevice, data: dispatch_data_t, error: **NSError) -> *MTLLibrary {
        _func: (obj: *void, selector: *void, data: dispatch_data_t, error: **NSError) -> *MTLLibrary #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.newLibraryWithData_error_, data, error);
    }

    newLibraryWithSource_options_error :: (self: *MTLDevice, source: *NSString, options: *MTLCompileOptions, error: **NSError) -> *MTLLibrary {
        _func: (obj: *void, selector: *void, source: *NSString, options: *MTLCompileOptions, error: **NSError) -> *MTLLibrary #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.newLibraryWithSource_options_error_, source, options, error);
    }

    newRenderPipelineStateWithDescriptor_error :: (self: *MTLDevice, descriptor: *MTLRenderPipelineDescriptor, error: **NSError) -> *MTLRenderPipelineState {
        _func: (obj: *void, selector: *void, descriptor: *MTLRenderPipelineDescriptor, error: **NSError) -> *MTLRenderPipelineState #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.newRenderPipelineStateWithDescriptor_error_, descriptor, error);
    }

    newRenderPipelineStateWithDescriptor_options_reflection_error :: (self: *MTLDevice, descriptor: *MTLRenderPipelineDescriptor, options: MTLPipelineOption, reflection: **MTLRenderPipelineReflection, error: **NSError) -> id {
        _func: (obj: *void, selector: *void, descriptor: *MTLRenderPipelineDescriptor, options: MTLPipelineOption, reflection: **MTLRenderPipelineReflection, error: **NSError) -> id #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.newRenderPipelineStateWithDescriptor_options_reflection_error_, descriptor, options, reflection, error);
    }

    newComputePipelineStateWithFunction_error :: (self: *MTLDevice, computeFunction: id, error: **NSError) -> *MTLComputePipelineState {
        _func: (obj: *void, selector: *void, computeFunction: id, error: **NSError) -> *MTLComputePipelineState #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.newComputePipelineStateWithFunction_error_, computeFunction, error);
    }

    newComputePipelineStateWithFunction_options_reflection_error :: (self: *MTLDevice, computeFunction: id, options: MTLPipelineOption, reflection: **MTLComputePipelineReflection, error: **NSError) -> *MTLComputePipelineState {
        _func: (obj: *void, selector: *void, computeFunction: id, options: MTLPipelineOption, reflection: **MTLComputePipelineReflection, error: **NSError) -> *MTLComputePipelineState #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.newComputePipelineStateWithFunction_options_reflection_error_, computeFunction, options, reflection, error);
    }

    newComputePipelineStateWithDescriptor_options_reflection_error :: (self: *MTLDevice, descriptor: *MTLComputePipelineDescriptor, options: MTLPipelineOption, reflection: **MTLComputePipelineReflection, error: **NSError) -> id {
        _func: (obj: *void, selector: *void, descriptor: *MTLComputePipelineDescriptor, options: MTLPipelineOption, reflection: **MTLComputePipelineReflection, error: **NSError) -> id #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.newComputePipelineStateWithDescriptor_options_reflection_error_, descriptor, options, reflection, error);
    }

    newFence :: (self: *MTLDevice) -> id {
        _func: (obj: *void, selector: *void) -> id #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.newFence);
    }

    supportsFamily :: (device : *MTLDevice, family : MTLGPUFamily) -> bool {
        _func : (obj : *void, selector : *void, family : MTLGPUFamily) -> BOOL #c_call;
        _func = xx objc_msgSend;

        return xx _func(device, __selectors.supportsFamily_, family);
    }

    supportsFeatureSet :: (self: *MTLDevice, featureSet: MTLFeatureSet) -> BOOL {
        _func: (obj: *void, selector: *void, featureSet: MTLFeatureSet) -> BOOL #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.supportsFeatureSet_, featureSet);
    }

    supportsTextureSampleCount :: (self: *MTLDevice, sampleCount: NSUInteger) -> BOOL {
        _func: (obj: *void, selector: *void, sampleCount: NSUInteger) -> BOOL #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.supportsTextureSampleCount_, sampleCount);
    }

    minimumLinearTextureAlignmentForPixelFormat :: (self: *MTLDevice, format: MTLPixelFormat) -> NSUInteger {
        _func: (obj: *void, selector: *void, format: MTLPixelFormat) -> NSUInteger #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.minimumLinearTextureAlignmentForPixelFormat_, format);
    }

    minimumTextureBufferAlignmentForPixelFormat :: (self: *MTLDevice, format: MTLPixelFormat) -> NSUInteger {
        _func: (obj: *void, selector: *void, format: MTLPixelFormat) -> NSUInteger #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.minimumTextureBufferAlignmentForPixelFormat_, format);
    }

    getDefaultSamplePositions_count :: (self: *MTLDevice, positions: *MTLSamplePosition, count: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, positions: *MTLSamplePosition, count: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.getDefaultSamplePositions_count_, positions, count);
    }

    newArgumentEncoderWithArguments :: (self: *MTLDevice, arguments: *NSArray(*MTLArgumentDescriptor)) -> id {
        _func: (obj: *void, selector: *void, arguments: *NSArray(*MTLArgumentDescriptor)) -> id #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.newArgumentEncoderWithArguments_, arguments);
    }

    newIndirectCommandBufferWithDescriptor_maxCommandCount_options :: (self: *MTLDevice, descriptor: *MTLIndirectCommandBufferDescriptor, maxCount: NSUInteger, options: MTLResourceOptions) -> id {
        _func: (obj: *void, selector: *void, descriptor: *MTLIndirectCommandBufferDescriptor, maxCount: NSUInteger, options: MTLResourceOptions) -> id #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.newIndirectCommandBufferWithDescriptor_maxCommandCount_options_, descriptor, maxCount, options);
    }

    newEvent :: (self: *MTLDevice) -> id {
        _func: (obj: *void, selector: *void) -> id #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.newEvent);
    }

    newSharedEvent :: (self: *MTLDevice) -> id {
        _func: (obj: *void, selector: *void) -> id #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.newSharedEvent);
    }

    newSharedEventWithHandle :: (self: *MTLDevice, sharedEventHandle: *MTLSharedEventHandle) -> id {
        _func: (obj: *void, selector: *void, sharedEventHandle: *MTLSharedEventHandle) -> id #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.newSharedEventWithHandle_, sharedEventHandle);
    }

    name :: (self: *MTLDevice) -> *NSString {
        _func: (obj: *void, selector: *void) -> *NSString #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.name);
    }

    supportsRaytracing :: (self: *MTLDevice) -> bool {
        _func: (obj: *void, selector: *void) -> bool #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.supportsRaytracing);
    }

    registryID :: (self: *MTLDevice) -> uint64_t {
        _func: (obj: *void, selector: *void) -> uint64_t #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.registryID);
    }

    maxThreadsPerThreadgroup :: (self: *MTLDevice) -> MTLSize {
        _func: (obj: *void, selector: *void) -> MTLSize #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.maxThreadsPerThreadgroup);
    }

    isLowPower :: (self: *MTLDevice) -> BOOL {
        _func: (obj: *void, selector: *void) -> BOOL #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.isLowPower);
    }

    isHeadless :: (self: *MTLDevice) -> BOOL {
        _func: (obj: *void, selector: *void) -> BOOL #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.isHeadless);
    }

    isRemovable :: (self: *MTLDevice) -> BOOL {
        _func: (obj: *void, selector: *void) -> BOOL #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.isRemovable);
    }

    recommendedMaxWorkingSetSize :: (self: *MTLDevice) -> uint64_t {
        _func: (obj: *void, selector: *void) -> uint64_t #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.recommendedMaxWorkingSetSize);
    }

    isDepth24Stencil8PixelFormatSupported :: (self: *MTLDevice) -> BOOL {
        _func: (obj: *void, selector: *void) -> BOOL #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.isDepth24Stencil8PixelFormatSupported);
    }

    readWriteTextureSupport :: (self: *MTLDevice) -> MTLReadWriteTextureTier {
        _func: (obj: *void, selector: *void) -> MTLReadWriteTextureTier #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.readWriteTextureSupport);
    }

    argumentBuffersSupport :: (self: *MTLDevice) -> MTLArgumentBuffersTier {
        _func: (obj: *void, selector: *void) -> MTLArgumentBuffersTier #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.argumentBuffersSupport);
    }

    areRasterOrderGroupsSupported :: (self: *MTLDevice) -> BOOL {
        _func: (obj: *void, selector: *void) -> BOOL #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.areRasterOrderGroupsSupported);
    }

    currentAllocatedSize :: (self: *MTLDevice) -> NSUInteger {
        _func: (obj: *void, selector: *void) -> NSUInteger #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.currentAllocatedSize);
    }

    maxThreadgroupMemoryLength :: (self: *MTLDevice) -> NSUInteger {
        _func: (obj: *void, selector: *void) -> NSUInteger #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.maxThreadgroupMemoryLength);
    }

    maxArgumentBufferSamplerCount :: (self: *MTLDevice) -> NSUInteger {
        _func: (obj: *void, selector: *void) -> NSUInteger #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.maxArgumentBufferSamplerCount);
    }

    areProgrammableSamplePositionsSupported :: (self: *MTLDevice) -> BOOL {
        _func: (obj: *void, selector: *void) -> BOOL #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.areProgrammableSamplePositionsSupported);
    }

    maxBufferLength :: (self: *MTLDevice) -> NSUInteger {
        _func: (obj: *void, selector: *void) -> NSUInteger #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.maxBufferLength);
    }

}

MTLFence :: struct {
    device :: (self: *MTLFence) -> id {
        _func: (obj: *void, selector: *void) -> id #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.device);
    }

    label :: (self: *MTLFence) -> *NSString {
        _func: (obj: *void, selector: *void) -> *NSString #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.label);
    }

    setLabel :: (self: *MTLFence, label: *NSString) -> () {
        _func: (obj: *void, selector: *void, label: *NSString) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setLabel_, label);
    }

}

using MTLBlitOption :: enum NSUInteger {
    MTLBlitOptionNone :: 0;
    MTLBlitOptionDepthFromDepthStencil :: 1;
    MTLBlitOptionStencilFromDepthStencil :: 2;
    MTLBlitOptionRowLinearPVRTC :: 4;
}



MTLBlitCommandEncoder :: struct {
    endEncoding :: (self: *MTLBlitCommandEncoder) -> () {
        _func: (obj: *void, selector: *void) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.endEncoding);
    }

    synchronizeResource :: (self: *MTLBlitCommandEncoder, resource: id) -> () {
        _func: (obj: *void, selector: *void, resource: id) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.synchronizeResource_, resource);
    }

    synchronizeTexture_slice_level :: (self: *MTLBlitCommandEncoder, texture: id, slice: NSUInteger, level: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, texture: id, slice: NSUInteger, level: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.synchronizeTexture_slice_level_, texture, slice, level);
    }

    copyFromTexture_sourceSlice_sourceLevel_sourceOrigin_sourceSize_toTexture_destinationSlice_destinationLevel_destinationOrigin :: (self: *MTLBlitCommandEncoder, sourceTexture: id, sourceSlice: NSUInteger, sourceLevel: NSUInteger, sourceOrigin: MTLOrigin, sourceSize: MTLSize, destinationTexture: id, destinationSlice: NSUInteger, destinationLevel: NSUInteger, destinationOrigin: MTLOrigin) -> () {
        _func: (obj: *void, selector: *void, sourceTexture: id, sourceSlice: NSUInteger, sourceLevel: NSUInteger, sourceOrigin: MTLOrigin, sourceSize: MTLSize, destinationTexture: id, destinationSlice: NSUInteger, destinationLevel: NSUInteger, destinationOrigin: MTLOrigin) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.copyFromTexture_sourceSlice_sourceLevel_sourceOrigin_sourceSize_toTexture_destinationSlice_destinationLevel_destinationOrigin_, sourceTexture, sourceSlice, sourceLevel, sourceOrigin, sourceSize, destinationTexture, destinationSlice, destinationLevel, destinationOrigin);
    }

    copyFromBuffer_sourceOffset_sourceBytesPerRow_sourceBytesPerImage_sourceSize_toTexture_destinationSlice_destinationLevel_destinationOrigin :: (self: *MTLBlitCommandEncoder, sourceBuffer: id, sourceOffset: NSUInteger, sourceBytesPerRow: NSUInteger, sourceBytesPerImage: NSUInteger, sourceSize: MTLSize, destinationTexture: id, destinationSlice: NSUInteger, destinationLevel: NSUInteger, destinationOrigin: MTLOrigin) -> () {
        _func: (obj: *void, selector: *void, sourceBuffer: id, sourceOffset: NSUInteger, sourceBytesPerRow: NSUInteger, sourceBytesPerImage: NSUInteger, sourceSize: MTLSize, destinationTexture: id, destinationSlice: NSUInteger, destinationLevel: NSUInteger, destinationOrigin: MTLOrigin) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.copyFromBuffer_sourceOffset_sourceBytesPerRow_sourceBytesPerImage_sourceSize_toTexture_destinationSlice_destinationLevel_destinationOrigin_, sourceBuffer, sourceOffset, sourceBytesPerRow, sourceBytesPerImage, sourceSize, destinationTexture, destinationSlice, destinationLevel, destinationOrigin);
    }

    copyFromBuffer_sourceOffset_sourceBytesPerRow_sourceBytesPerImage_sourceSize_toTexture_destinationSlice_destinationLevel_destinationOrigin_options :: (self: *MTLBlitCommandEncoder, sourceBuffer: id, sourceOffset: NSUInteger, sourceBytesPerRow: NSUInteger, sourceBytesPerImage: NSUInteger, sourceSize: MTLSize, destinationTexture: id, destinationSlice: NSUInteger, destinationLevel: NSUInteger, destinationOrigin: MTLOrigin, options: MTLBlitOption) -> () {
        _func: (obj: *void, selector: *void, sourceBuffer: id, sourceOffset: NSUInteger, sourceBytesPerRow: NSUInteger, sourceBytesPerImage: NSUInteger, sourceSize: MTLSize, destinationTexture: id, destinationSlice: NSUInteger, destinationLevel: NSUInteger, destinationOrigin: MTLOrigin, options: MTLBlitOption) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.copyFromBuffer_sourceOffset_sourceBytesPerRow_sourceBytesPerImage_sourceSize_toTexture_destinationSlice_destinationLevel_destinationOrigin_options_, sourceBuffer, sourceOffset, sourceBytesPerRow, sourceBytesPerImage, sourceSize, destinationTexture, destinationSlice, destinationLevel, destinationOrigin, options);
    }

    copyFromTexture_sourceSlice_sourceLevel_sourceOrigin_sourceSize_toBuffer_destinationOffset_destinationBytesPerRow_destinationBytesPerImage :: (self: *MTLBlitCommandEncoder, sourceTexture: id, sourceSlice: NSUInteger, sourceLevel: NSUInteger, sourceOrigin: MTLOrigin, sourceSize: MTLSize, destinationBuffer: id, destinationOffset: NSUInteger, destinationBytesPerRow: NSUInteger, destinationBytesPerImage: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, sourceTexture: id, sourceSlice: NSUInteger, sourceLevel: NSUInteger, sourceOrigin: MTLOrigin, sourceSize: MTLSize, destinationBuffer: id, destinationOffset: NSUInteger, destinationBytesPerRow: NSUInteger, destinationBytesPerImage: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.copyFromTexture_sourceSlice_sourceLevel_sourceOrigin_sourceSize_toBuffer_destinationOffset_destinationBytesPerRow_destinationBytesPerImage_, sourceTexture, sourceSlice, sourceLevel, sourceOrigin, sourceSize, destinationBuffer, destinationOffset, destinationBytesPerRow, destinationBytesPerImage);
    }

    copyFromTexture_sourceSlice_sourceLevel_sourceOrigin_sourceSize_toBuffer_destinationOffset_destinationBytesPerRow_destinationBytesPerImage_options :: (self: *MTLBlitCommandEncoder, sourceTexture: id, sourceSlice: NSUInteger, sourceLevel: NSUInteger, sourceOrigin: MTLOrigin, sourceSize: MTLSize, destinationBuffer: id, destinationOffset: NSUInteger, destinationBytesPerRow: NSUInteger, destinationBytesPerImage: NSUInteger, options: MTLBlitOption) -> () {
        _func: (obj: *void, selector: *void, sourceTexture: id, sourceSlice: NSUInteger, sourceLevel: NSUInteger, sourceOrigin: MTLOrigin, sourceSize: MTLSize, destinationBuffer: id, destinationOffset: NSUInteger, destinationBytesPerRow: NSUInteger, destinationBytesPerImage: NSUInteger, options: MTLBlitOption) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.copyFromTexture_sourceSlice_sourceLevel_sourceOrigin_sourceSize_toBuffer_destinationOffset_destinationBytesPerRow_destinationBytesPerImage_options_, sourceTexture, sourceSlice, sourceLevel, sourceOrigin, sourceSize, destinationBuffer, destinationOffset, destinationBytesPerRow, destinationBytesPerImage, options);
    }

    generateMipmapsForTexture :: (self: *MTLBlitCommandEncoder, texture: id) -> () {
        _func: (obj: *void, selector: *void, texture: id) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.generateMipmapsForTexture_, texture);
    }

    fillBuffer_range_value :: (self: *MTLBlitCommandEncoder, buffer: id, range: NSRange, value: uint8_t) -> () {
        _func: (obj: *void, selector: *void, buffer: id, range: NSRange, value: uint8_t) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.fillBuffer_range_value_, buffer, range, value);
    }

    copyFromBuffer_sourceOffset_toBuffer_destinationOffset_size :: (self: *MTLBlitCommandEncoder, sourceBuffer: id, sourceOffset: NSUInteger, destinationBuffer: id, destinationOffset: NSUInteger, size: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, sourceBuffer: id, sourceOffset: NSUInteger, destinationBuffer: id, destinationOffset: NSUInteger, size: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.copyFromBuffer_sourceOffset_toBuffer_destinationOffset_size_, sourceBuffer, sourceOffset, destinationBuffer, destinationOffset, size);
    }

    updateFence :: (self: *MTLBlitCommandEncoder, fence: id) -> () {
        _func: (obj: *void, selector: *void, fence: id) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.updateFence_, fence);
    }

    waitForFence :: (self: *MTLBlitCommandEncoder, fence: id) -> () {
        _func: (obj: *void, selector: *void, fence: id) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.waitForFence_, fence);
    }

    optimizeContentsForGPUAccess :: (self: *MTLBlitCommandEncoder, texture: id) -> () {
        _func: (obj: *void, selector: *void, texture: id) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.optimizeContentsForGPUAccess_, texture);
    }

    optimizeContentsForGPUAccess_slice_level :: (self: *MTLBlitCommandEncoder, texture: id, slice: NSUInteger, level: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, texture: id, slice: NSUInteger, level: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.optimizeContentsForGPUAccess_slice_level_, texture, slice, level);
    }

    optimizeContentsForCPUAccess :: (self: *MTLBlitCommandEncoder, texture: id) -> () {
        _func: (obj: *void, selector: *void, texture: id) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.optimizeContentsForCPUAccess_, texture);
    }

    optimizeContentsForCPUAccess_slice_level :: (self: *MTLBlitCommandEncoder, texture: id, slice: NSUInteger, level: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, texture: id, slice: NSUInteger, level: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.optimizeContentsForCPUAccess_slice_level_, texture, slice, level);
    }

    resetCommandsInBuffer_withRange :: (self: *MTLBlitCommandEncoder, buffer: id, range: NSRange) -> () {
        _func: (obj: *void, selector: *void, buffer: id, range: NSRange) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.resetCommandsInBuffer_withRange_, buffer, range);
    }

    copyIndirectCommandBuffer_sourceRange_destination_destinationIndex :: (self: *MTLBlitCommandEncoder, source: id, sourceRange: NSRange, destination: id, destinationIndex: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, source: id, sourceRange: NSRange, destination: id, destinationIndex: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.copyIndirectCommandBuffer_sourceRange_destination_destinationIndex_, source, sourceRange, destination, destinationIndex);
    }

    optimizeIndirectCommandBuffer_withRange :: (self: *MTLBlitCommandEncoder, indirectCommandBuffer: id, range: NSRange) -> () {
        _func: (obj: *void, selector: *void, indirectCommandBuffer: id, range: NSRange) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.optimizeIndirectCommandBuffer_withRange_, indirectCommandBuffer, range);
    }

}

using MTLCommandBufferStatus :: enum NSUInteger {
    MTLCommandBufferStatusNotEnqueued :: 0;
    MTLCommandBufferStatusEnqueued :: 1;
    MTLCommandBufferStatusCommitted :: 2;
    MTLCommandBufferStatusScheduled :: 3;
    MTLCommandBufferStatusCompleted :: 4;
    MTLCommandBufferStatusError :: 5;
}



MTLCommandBufferErrorDomain: *NSString;

using MTLCommandBufferError :: enum NSUInteger {
    MTLCommandBufferErrorNone :: 0;
    MTLCommandBufferErrorInternal :: 1;
    MTLCommandBufferErrorTimeout :: 2;
    MTLCommandBufferErrorPageFault :: 3;
    MTLCommandBufferErrorBlacklisted :: 4;
    MTLCommandBufferErrorNotPermitted :: 7;
    MTLCommandBufferErrorOutOfMemory :: 8;
    MTLCommandBufferErrorInvalidResource :: 9;
    MTLCommandBufferErrorMemoryless :: 10;
    MTLCommandBufferErrorDeviceRemoved :: 11;
}



using MTLDispatchType :: enum NSUInteger {
    MTLDispatchTypeSerial :: 0;
    MTLDispatchTypeConcurrent :: 1;
}


MTLCommandBuffer :: struct {

    MTLCommandBufferHandler :: *void;

    completedHandler:: (self: *MTLCommandBuffer) -> MTLCommandBufferHandler {
        _func: (obj: *void, selector: *void) -> *void #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.completedHandler);
    }

    addCompletedHandler:: (self: *MTLCommandBuffer, completedHandler: *void) -> () {
        _func: (obj: *void, selector: *void, completedHandler: *void) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.addCompletedHandler_, completedHandler);
    }

    enqueue :: (self: *MTLCommandBuffer) -> () {
        _func: (obj: *void, selector: *void) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.enqueue);
    }

    commit :: (self: *MTLCommandBuffer) -> () {
        _func: (obj: *void, selector: *void) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.commit);
    }

    presentDrawable :: (self: *MTLCommandBuffer, drawable: id) -> () {
        _func: (obj: *void, selector: *void, drawable: id) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.presentDrawable_, drawable);
    }

    presentDrawable_atTime :: (self: *MTLCommandBuffer, drawable: id, presentationTime: CFTimeInterval) -> () {
        _func: (obj: *void, selector: *void, drawable: id, presentationTime: CFTimeInterval) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.presentDrawable_atTime_, drawable, presentationTime);
    }

    waitUntilScheduled :: (self: *MTLCommandBuffer) -> () {
        _func: (obj: *void, selector: *void) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.waitUntilScheduled);
    }

    waitUntilCompleted :: (self: *MTLCommandBuffer) -> () {
        _func: (obj: *void, selector: *void) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.waitUntilCompleted);
    }

    blitCommandEncoder :: (self: *MTLCommandBuffer) -> *MTLBlitCommandEncoder {
        _func: (obj: *void, selector: *void) -> *MTLBlitCommandEncoder #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.blitCommandEncoder);
    }

    renderCommandEncoderWithDescriptor :: (self: *MTLCommandBuffer, renderPassDescriptor: *MTLRenderPassDescriptor) -> *MTLRenderCommandEncoder {
        _func: (obj: *void, selector: *void, renderPassDescriptor: *MTLRenderPassDescriptor) -> *MTLRenderCommandEncoder #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.renderCommandEncoderWithDescriptor_, renderPassDescriptor);
    }

    computeCommandEncoder :: (self: *MTLCommandBuffer) -> *MTLComputeCommandEncoder {
        _func: (obj: *void, selector: *void) -> *MTLComputeCommandEncoder #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.computeCommandEncoder);
    }

    computeCommandEncoderWithDispatchType :: (self: *MTLCommandBuffer, dispatchType: MTLDispatchType) -> *MTLComputeCommandEncoder {
        _func: (obj: *void, selector: *void, dispatchType: MTLDispatchType) -> *MTLComputeCommandEncoder #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.computeCommandEncoderWithDispatchType_, dispatchType);
    }

    encodeWaitForEvent_value :: (self: *MTLCommandBuffer, event: id, value: uint64_t) -> () {
        _func: (obj: *void, selector: *void, event: id, value: uint64_t) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.encodeWaitForEvent_value_, event, value);
    }

    encodeSignalEvent_value :: (self: *MTLCommandBuffer, event: id, value: uint64_t) -> () {
        _func: (obj: *void, selector: *void, event: id, value: uint64_t) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.encodeSignalEvent_value_, event, value);
    }

    parallelRenderCommandEncoderWithDescriptor :: (self: *MTLCommandBuffer, renderPassDescriptor: *MTLRenderPassDescriptor) -> id {
        _func: (obj: *void, selector: *void, renderPassDescriptor: *MTLRenderPassDescriptor) -> id #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.parallelRenderCommandEncoderWithDescriptor_, renderPassDescriptor);
    }

    pushDebugGroup :: (self: *MTLCommandBuffer, _string: *NSString) -> () {
        _func: (obj: *void, selector: *void, _string: *NSString) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.pushDebugGroup_, _string);
    }

    popDebugGroup :: (self: *MTLCommandBuffer) -> () {
        _func: (obj: *void, selector: *void) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.popDebugGroup);
    }

    device :: (self: *MTLCommandBuffer) -> id {
        _func: (obj: *void, selector: *void) -> id #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.device);
    }

    commandQueue :: (self: *MTLCommandBuffer) -> id {
        _func: (obj: *void, selector: *void) -> id #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.commandQueue);
    }

    retainedReferences :: (self: *MTLCommandBuffer) -> BOOL {
        _func: (obj: *void, selector: *void) -> BOOL #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.retainedReferences);
    }

    label :: (self: *MTLCommandBuffer) -> *NSString {
        _func: (obj: *void, selector: *void) -> *NSString #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.label);
    }

    setLabel :: (self: *MTLCommandBuffer, label: *NSString) -> () {
        _func: (obj: *void, selector: *void, label: *NSString) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setLabel_, label);
    }

    kernelStartTime :: (self: *MTLCommandBuffer) -> CFTimeInterval {
        _func: (obj: *void, selector: *void) -> CFTimeInterval #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.kernelStartTime);
    }

    kernelEndTime :: (self: *MTLCommandBuffer) -> CFTimeInterval {
        _func: (obj: *void, selector: *void) -> CFTimeInterval #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.kernelEndTime);
    }

    GPUStartTime :: (self: *MTLCommandBuffer) -> CFTimeInterval {
        _func: (obj: *void, selector: *void) -> CFTimeInterval #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.GPUStartTime);
    }

    GPUEndTime :: (self: *MTLCommandBuffer) -> CFTimeInterval {
        _func: (obj: *void, selector: *void) -> CFTimeInterval #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.GPUEndTime);
    }

    status :: (self: *MTLCommandBuffer) -> MTLCommandBufferStatus {
        _func: (obj: *void, selector: *void) -> MTLCommandBufferStatus #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.status);
    }

    error :: (self: *MTLCommandBuffer) -> *NSError {
        _func: (obj: *void, selector: *void) -> *NSError #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.error);
    }

}

MTLDispatchThreadgroupsIndirectArguments :: struct {
    threadgroupsPerGrid: [3] uint32_t;
}

MTLStageInRegionIndirectArguments :: struct {
    stageInOrigin: [3] uint32_t;
    stageInSize: [3] uint32_t;
}

MTLComputeCommandEncoder :: struct {
    setComputePipelineState :: (self: *MTLComputeCommandEncoder, state: id) -> () {
        _func: (obj: *void, selector: *void, state: id) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setComputePipelineState_, state);
    }

    setBytes_length_atIndex :: (self: *MTLComputeCommandEncoder, bytes: *void, length: NSUInteger, index: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, bytes: *void, length: NSUInteger, index: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setBytes_length_atIndex_, bytes, length, index);
    }

    setBuffer_offset_atIndex :: (self: *MTLComputeCommandEncoder, buffer: id, offset: NSUInteger, index: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, buffer: id, offset: NSUInteger, index: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setBuffer_offset_atIndex_, buffer, offset, index);
    }

    setBufferOffset_atIndex :: (self: *MTLComputeCommandEncoder, offset: NSUInteger, index: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, offset: NSUInteger, index: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setBufferOffset_atIndex_, offset, index);
    }

    setBuffers_offsets_withRange :: (self: *MTLComputeCommandEncoder, buffers: *id, offsets: *NSUInteger, range: NSRange) -> () {
        _func: (obj: *void, selector: *void, buffers: *id, offsets: *NSUInteger, range: NSRange) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setBuffers_offsets_withRange_, buffers, offsets, range);
    }

    setTexture_atIndex :: (self: *MTLComputeCommandEncoder, texture: id, index: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, texture: id, index: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setTexture_atIndex_, texture, index);
    }

    setTextures_withRange :: (self: *MTLComputeCommandEncoder, textures: *id, range: NSRange) -> () {
        _func: (obj: *void, selector: *void, textures: *id, range: NSRange) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setTextures_withRange_, textures, range);
    }

    setSamplerState_atIndex :: (self: *MTLComputeCommandEncoder, sampler: id, index: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, sampler: id, index: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setSamplerState_atIndex_, sampler, index);
    }

    setSamplerStates_withRange :: (self: *MTLComputeCommandEncoder, samplers: *id, range: NSRange) -> () {
        _func: (obj: *void, selector: *void, samplers: *id, range: NSRange) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setSamplerStates_withRange_, samplers, range);
    }

    setSamplerState_lodMinClamp_lodMaxClamp_atIndex :: (self: *MTLComputeCommandEncoder, sampler: id, lodMinClamp: float32, lodMaxClamp: float32, index: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, sampler: id, lodMinClamp: float32, lodMaxClamp: float32, index: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setSamplerState_lodMinClamp_lodMaxClamp_atIndex_, sampler, lodMinClamp, lodMaxClamp, index);
    }

    setSamplerStates_lodMinClamps_lodMaxClamps_withRange :: (self: *MTLComputeCommandEncoder, samplers: *id, lodMinClamps: *float32, lodMaxClamps: *float32, range: NSRange) -> () {
        _func: (obj: *void, selector: *void, samplers: *id, lodMinClamps: *float32, lodMaxClamps: *float32, range: NSRange) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setSamplerStates_lodMinClamps_lodMaxClamps_withRange_, samplers, lodMinClamps, lodMaxClamps, range);
    }

    setThreadgroupMemoryLength_atIndex :: (self: *MTLComputeCommandEncoder, length: NSUInteger, index: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, length: NSUInteger, index: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setThreadgroupMemoryLength_atIndex_, length, index);
    }

    setStageInRegion :: (self: *MTLComputeCommandEncoder, region: MTLRegion) -> () {
        _func: (obj: *void, selector: *void, region: MTLRegion) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setStageInRegion_, region);
    }

    setStageInRegionWithIndirectBuffer_indirectBufferOffset :: (self: *MTLComputeCommandEncoder, indirectBuffer: id, indirectBufferOffset: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, indirectBuffer: id, indirectBufferOffset: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setStageInRegionWithIndirectBuffer_indirectBufferOffset_, indirectBuffer, indirectBufferOffset);
    }

    dispatchThreadgroups_threadsPerThreadgroup :: (self: *MTLComputeCommandEncoder, threadgroupsPerGrid: MTLSize, threadsPerThreadgroup: MTLSize) -> () {
        _func: (obj: *void, selector: *void, threadgroupsPerGrid: MTLSize, threadsPerThreadgroup: MTLSize) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.dispatchThreadgroups_threadsPerThreadgroup_, threadgroupsPerGrid, threadsPerThreadgroup);
    }

    dispatchThreadgroupsWithIndirectBuffer_indirectBufferOffset_threadsPerThreadgroup :: (self: *MTLComputeCommandEncoder, indirectBuffer: id, indirectBufferOffset: NSUInteger, threadsPerThreadgroup: MTLSize) -> () {
        _func: (obj: *void, selector: *void, indirectBuffer: id, indirectBufferOffset: NSUInteger, threadsPerThreadgroup: MTLSize) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.dispatchThreadgroupsWithIndirectBuffer_indirectBufferOffset_threadsPerThreadgroup_, indirectBuffer, indirectBufferOffset, threadsPerThreadgroup);
    }

    dispatchThreads_threadsPerThreadgroup :: (self: *MTLComputeCommandEncoder, threadsPerGrid: MTLSize, threadsPerThreadgroup: MTLSize) -> () {
        _func: (obj: *void, selector: *void, threadsPerGrid: MTLSize, threadsPerThreadgroup: MTLSize) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.dispatchThreads_threadsPerThreadgroup_, threadsPerGrid, threadsPerThreadgroup);
    }

    updateFence :: (self: *MTLComputeCommandEncoder, fence: id) -> () {
        _func: (obj: *void, selector: *void, fence: id) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.updateFence_, fence);
    }

    waitForFence :: (self: *MTLComputeCommandEncoder, fence: id) -> () {
        _func: (obj: *void, selector: *void, fence: id) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.waitForFence_, fence);
    }

    useResource_usage :: (self: *MTLComputeCommandEncoder, resource: id, usage: MTLResourceUsage) -> () {
        _func: (obj: *void, selector: *void, resource: id, usage: MTLResourceUsage) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.useResource_usage_, resource, usage);
    }

    useResources_count_usage :: (self: *MTLComputeCommandEncoder, resources: *id, count: NSUInteger, usage: MTLResourceUsage) -> () {
        _func: (obj: *void, selector: *void, resources: *id, count: NSUInteger, usage: MTLResourceUsage) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.useResources_count_usage_, resources, count, usage);
    }

    useHeap :: (self: *MTLComputeCommandEncoder, heap: id) -> () {
        _func: (obj: *void, selector: *void, heap: id) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.useHeap_, heap);
    }

    useHeaps_count :: (self: *MTLComputeCommandEncoder, heaps: *id, count: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, heaps: *id, count: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.useHeaps_count_, heaps, count);
    }

    memoryBarrierWithScope :: (self: *MTLComputeCommandEncoder, scope: MTLBarrierScope) -> () {
        _func: (obj: *void, selector: *void, scope: MTLBarrierScope) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.memoryBarrierWithScope_, scope);
    }

    memoryBarrierWithResources_count :: (self: *MTLComputeCommandEncoder, resources: *id, count: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, resources: *id, count: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.memoryBarrierWithResources_count_, resources, count);
    }

    dispatchType :: (self: *MTLComputeCommandEncoder) -> MTLDispatchType {
        _func: (obj: *void, selector: *void) -> MTLDispatchType #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.dispatchType);
    }

}

MTLCommandQueue :: struct {
    commandBuffer :: (self: *MTLCommandQueue) -> *MTLCommandBuffer {
        _func: (obj: *void, selector: *void) -> *MTLCommandBuffer #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.commandBuffer);
    }

    commandBufferWithUnretainedReferences :: (self: *MTLCommandQueue) -> *MTLCommandBuffer {
        _func: (obj: *void, selector: *void) -> *MTLCommandBuffer #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.commandBufferWithUnretainedReferences);
    }

    insertDebugCaptureBoundary :: (self: *MTLCommandQueue) -> () {
        _func: (obj: *void, selector: *void) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.insertDebugCaptureBoundary);
    }

    label :: (self: *MTLCommandQueue) -> *NSString {
        _func: (obj: *void, selector: *void) -> *NSString #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.label);
    }

    setLabel :: (self: *MTLCommandQueue, label: *NSString) -> () {
        _func: (obj: *void, selector: *void, label: *NSString) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setLabel_, label);
    }

    device :: (self: *MTLCommandQueue) -> id {
        _func: (obj: *void, selector: *void) -> id #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.device);
    }

}

using MTLCompareFunction :: enum NSUInteger {
    MTLCompareFunctionNever :: 0;
    MTLCompareFunctionLess :: 1;
    MTLCompareFunctionEqual :: 2;
    MTLCompareFunctionLessEqual :: 3;
    MTLCompareFunctionGreater :: 4;
    MTLCompareFunctionNotEqual :: 5;
    MTLCompareFunctionGreaterEqual :: 6;
    MTLCompareFunctionAlways :: 7;
}



using MTLStencilOperation :: enum NSUInteger {
    MTLStencilOperationKeep :: 0;
    MTLStencilOperationZero :: 1;
    MTLStencilOperationReplace :: 2;
    MTLStencilOperationIncrementClamp :: 3;
    MTLStencilOperationDecrementClamp :: 4;
    MTLStencilOperationInvert :: 5;
    MTLStencilOperationIncrementWrap :: 6;
    MTLStencilOperationDecrementWrap :: 7;
}



MTLStencilDescriptor :: struct {
    nsobject: NSObject;
    stencilCompareFunction :: (self: *MTLStencilDescriptor) -> MTLCompareFunction {
        _func: (obj: *void, selector: *void) -> MTLCompareFunction #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.stencilCompareFunction);
    }

    setStencilCompareFunction :: (self: *MTLStencilDescriptor, stencilCompareFunction: MTLCompareFunction) -> () {
        _func: (obj: *void, selector: *void, stencilCompareFunction: MTLCompareFunction) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setStencilCompareFunction_, stencilCompareFunction);
    }

    stencilFailureOperation :: (self: *MTLStencilDescriptor) -> MTLStencilOperation {
        _func: (obj: *void, selector: *void) -> MTLStencilOperation #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.stencilFailureOperation);
    }

    setStencilFailureOperation :: (self: *MTLStencilDescriptor, stencilFailureOperation: MTLStencilOperation) -> () {
        _func: (obj: *void, selector: *void, stencilFailureOperation: MTLStencilOperation) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setStencilFailureOperation_, stencilFailureOperation);
    }

    depthFailureOperation :: (self: *MTLStencilDescriptor) -> MTLStencilOperation {
        _func: (obj: *void, selector: *void) -> MTLStencilOperation #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.depthFailureOperation);
    }

    setDepthFailureOperation :: (self: *MTLStencilDescriptor, depthFailureOperation: MTLStencilOperation) -> () {
        _func: (obj: *void, selector: *void, depthFailureOperation: MTLStencilOperation) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setDepthFailureOperation_, depthFailureOperation);
    }

    depthStencilPassOperation :: (self: *MTLStencilDescriptor) -> MTLStencilOperation {
        _func: (obj: *void, selector: *void) -> MTLStencilOperation #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.depthStencilPassOperation);
    }

    setDepthStencilPassOperation :: (self: *MTLStencilDescriptor, depthStencilPassOperation: MTLStencilOperation) -> () {
        _func: (obj: *void, selector: *void, depthStencilPassOperation: MTLStencilOperation) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setDepthStencilPassOperation_, depthStencilPassOperation);
    }

    readMask :: (self: *MTLStencilDescriptor) -> uint32_t {
        _func: (obj: *void, selector: *void) -> uint32_t #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.readMask);
    }

    setReadMask :: (self: *MTLStencilDescriptor, readMask: uint32_t) -> () {
        _func: (obj: *void, selector: *void, readMask: uint32_t) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setReadMask_, readMask);
    }

    writeMask :: (self: *MTLStencilDescriptor) -> uint32_t {
        _func: (obj: *void, selector: *void) -> uint32_t #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.writeMask);
    }

    setWriteMask :: (self: *MTLStencilDescriptor, writeMask: uint32_t) -> () {
        _func: (obj: *void, selector: *void, writeMask: uint32_t) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setWriteMask_, writeMask);
    }

}

MTLDepthStencilDescriptor :: struct {
    nsobject: NSObject;
    depthCompareFunction :: (self: *MTLDepthStencilDescriptor) -> MTLCompareFunction {
        _func: (obj: *void, selector: *void) -> MTLCompareFunction #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.depthCompareFunction);
    }

    setDepthCompareFunction :: (self: *MTLDepthStencilDescriptor, depthCompareFunction: MTLCompareFunction) -> () {
        _func: (obj: *void, selector: *void, depthCompareFunction: MTLCompareFunction) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setDepthCompareFunction_, depthCompareFunction);
    }

    isDepthWriteEnabled :: (self: *MTLDepthStencilDescriptor) -> BOOL {
        _func: (obj: *void, selector: *void) -> BOOL #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.isDepthWriteEnabled);
    }

    setDepthWriteEnabled :: (self: *MTLDepthStencilDescriptor, depthWriteEnabled: BOOL) -> () {
        _func: (obj: *void, selector: *void, depthWriteEnabled: BOOL) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setDepthWriteEnabled_, depthWriteEnabled);
    }

    frontFaceStencil :: (self: *MTLDepthStencilDescriptor) -> *MTLStencilDescriptor {
        _func: (obj: *void, selector: *void) -> *MTLStencilDescriptor #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.frontFaceStencil);
    }

    setFrontFaceStencil :: (self: *MTLDepthStencilDescriptor, frontFaceStencil: *MTLStencilDescriptor) -> () {
        _func: (obj: *void, selector: *void, frontFaceStencil: *MTLStencilDescriptor) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setFrontFaceStencil_, frontFaceStencil);
    }

    backFaceStencil :: (self: *MTLDepthStencilDescriptor) -> *MTLStencilDescriptor {
        _func: (obj: *void, selector: *void) -> *MTLStencilDescriptor #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.backFaceStencil);
    }

    setBackFaceStencil :: (self: *MTLDepthStencilDescriptor, backFaceStencil: *MTLStencilDescriptor) -> () {
        _func: (obj: *void, selector: *void, backFaceStencil: *MTLStencilDescriptor) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setBackFaceStencil_, backFaceStencil);
    }

    label :: (self: *MTLDepthStencilDescriptor) -> *NSString {
        _func: (obj: *void, selector: *void) -> *NSString #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.label);
    }

    setLabel :: (self: *MTLDepthStencilDescriptor, label: *NSString) -> () {
        _func: (obj: *void, selector: *void, label: *NSString) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setLabel_, label);
    }

}

MTLDepthStencilState :: struct {
    label :: (self: *MTLDepthStencilState) -> *NSString {
        _func: (obj: *void, selector: *void) -> *NSString #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.label);
    }

    device :: (self: *MTLDepthStencilState) -> id {
        _func: (obj: *void, selector: *void) -> id #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.device);
    }

}

MTLDrawable :: struct {
    present :: (self: *MTLDrawable) -> () {
        _func: (obj: *void, selector: *void) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.present);
    }

    presentAtTime :: (self: *MTLDrawable, presentationTime: CFTimeInterval) -> () {
        _func: (obj: *void, selector: *void, presentationTime: CFTimeInterval) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.presentAtTime_, presentationTime);
    }

}

using MTLLoadAction :: enum NSUInteger {
    MTLLoadActionDontCare :: 0;
    MTLLoadActionLoad :: 1;
    MTLLoadActionClear :: 2;
}



using MTLStoreAction :: enum NSUInteger {
    MTLStoreActionDontCare :: 0;
    MTLStoreActionStore :: 1;
    MTLStoreActionMultisampleResolve :: 2;
    MTLStoreActionStoreAndMultisampleResolve :: 3;
    MTLStoreActionUnknown :: 4;
    MTLStoreActionCustomSampleDepthStore :: 5;
}



using MTLStoreActionOptions :: enum NSUInteger {
    MTLStoreActionOptionNone :: 0;
    MTLStoreActionOptionCustomSamplePositions :: 1;
}



MTLClearColor :: struct {
    red: float64;
    green: float64;
    blue: float64;
    alpha: float64;
}

MTLRenderPassAttachmentDescriptor :: struct {
    nsobject: NSObject;
    texture :: (self: *MTLRenderPassAttachmentDescriptor) -> id {
        _func: (obj: *void, selector: *void) -> id #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.texture);
    }

    setTexture :: (self: *MTLRenderPassAttachmentDescriptor, texture: id) -> () {
        _func: (obj: *void, selector: *void, texture: id) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setTexture_, texture);
    }

    level :: (self: *MTLRenderPassAttachmentDescriptor) -> NSUInteger {
        _func: (obj: *void, selector: *void) -> NSUInteger #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.level);
    }

    setLevel :: (self: *MTLRenderPassAttachmentDescriptor, level: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, level: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setLevel_, level);
    }

    slice :: (self: *MTLRenderPassAttachmentDescriptor) -> NSUInteger {
        _func: (obj: *void, selector: *void) -> NSUInteger #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.slice);
    }

    setSlice :: (self: *MTLRenderPassAttachmentDescriptor, slice: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, slice: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setSlice_, slice);
    }

    depthPlane :: (self: *MTLRenderPassAttachmentDescriptor) -> NSUInteger {
        _func: (obj: *void, selector: *void) -> NSUInteger #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.depthPlane);
    }

    setDepthPlane :: (self: *MTLRenderPassAttachmentDescriptor, depthPlane: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, depthPlane: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setDepthPlane_, depthPlane);
    }

    resolveTexture :: (self: *MTLRenderPassAttachmentDescriptor) -> id {
        _func: (obj: *void, selector: *void) -> id #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.resolveTexture);
    }

    setResolveTexture :: (self: *MTLRenderPassAttachmentDescriptor, resolveTexture: id) -> () {
        _func: (obj: *void, selector: *void, resolveTexture: id) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setResolveTexture_, resolveTexture);
    }

    resolveLevel :: (self: *MTLRenderPassAttachmentDescriptor) -> NSUInteger {
        _func: (obj: *void, selector: *void) -> NSUInteger #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.resolveLevel);
    }

    setResolveLevel :: (self: *MTLRenderPassAttachmentDescriptor, resolveLevel: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, resolveLevel: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setResolveLevel_, resolveLevel);
    }

    resolveSlice :: (self: *MTLRenderPassAttachmentDescriptor) -> NSUInteger {
        _func: (obj: *void, selector: *void) -> NSUInteger #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.resolveSlice);
    }

    setResolveSlice :: (self: *MTLRenderPassAttachmentDescriptor, resolveSlice: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, resolveSlice: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setResolveSlice_, resolveSlice);
    }

    resolveDepthPlane :: (self: *MTLRenderPassAttachmentDescriptor) -> NSUInteger {
        _func: (obj: *void, selector: *void) -> NSUInteger #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.resolveDepthPlane);
    }

    setResolveDepthPlane :: (self: *MTLRenderPassAttachmentDescriptor, resolveDepthPlane: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, resolveDepthPlane: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setResolveDepthPlane_, resolveDepthPlane);
    }

    loadAction :: (self: *MTLRenderPassAttachmentDescriptor) -> MTLLoadAction {
        _func: (obj: *void, selector: *void) -> MTLLoadAction #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.loadAction);
    }

    setLoadAction :: (self: *MTLRenderPassAttachmentDescriptor, loadAction: MTLLoadAction) -> () {
        _func: (obj: *void, selector: *void, loadAction: MTLLoadAction) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setLoadAction_, loadAction);
    }

    storeAction :: (self: *MTLRenderPassAttachmentDescriptor) -> MTLStoreAction {
        _func: (obj: *void, selector: *void) -> MTLStoreAction #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.storeAction);
    }

    setStoreAction :: (self: *MTLRenderPassAttachmentDescriptor, storeAction: MTLStoreAction) -> () {
        _func: (obj: *void, selector: *void, storeAction: MTLStoreAction) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setStoreAction_, storeAction);
    }

    storeActionOptions :: (self: *MTLRenderPassAttachmentDescriptor) -> MTLStoreActionOptions {
        _func: (obj: *void, selector: *void) -> MTLStoreActionOptions #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.storeActionOptions);
    }

    setStoreActionOptions :: (self: *MTLRenderPassAttachmentDescriptor, storeActionOptions: MTLStoreActionOptions) -> () {
        _func: (obj: *void, selector: *void, storeActionOptions: MTLStoreActionOptions) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setStoreActionOptions_, storeActionOptions);
    }

}

MTLRenderPassColorAttachmentDescriptor :: struct {
    using #as mtlrenderpassattachmentdescriptor: MTLRenderPassAttachmentDescriptor;

    clearColor :: (self: *MTLRenderPassColorAttachmentDescriptor) -> MTLClearColor {
        _func: (obj: *void, selector: *void) -> MTLClearColor #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.clearColor);
    }

    setClearColor :: (self: *MTLRenderPassColorAttachmentDescriptor, clearColor: MTLClearColor) -> () {
        _func: (obj: *void, selector: *void, clearColor: MTLClearColor) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setClearColor_, clearColor);
    }

}

using MTLMultisampleDepthResolveFilter :: enum NSUInteger {
    MTLMultisampleDepthResolveFilterSample0 :: 0;
    MTLMultisampleDepthResolveFilterMin :: 1;
    MTLMultisampleDepthResolveFilterMax :: 2;
}



MTLRenderPassDepthAttachmentDescriptor :: struct {
    using #as mtlrenderpassattachmentdescriptor: MTLRenderPassAttachmentDescriptor;

    clearDepth :: (self: *MTLRenderPassDepthAttachmentDescriptor) -> float64 {
        _func: (obj: *void, selector: *void) -> float64 #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.clearDepth);
    }

    setClearDepth :: (self: *MTLRenderPassDepthAttachmentDescriptor, clearDepth: float64) -> () {
        _func: (obj: *void, selector: *void, clearDepth: float64) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setClearDepth_, clearDepth);
    }

    depthResolveFilter :: (self: *MTLRenderPassDepthAttachmentDescriptor) -> MTLMultisampleDepthResolveFilter {
        _func: (obj: *void, selector: *void) -> MTLMultisampleDepthResolveFilter #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.depthResolveFilter);
    }

    setDepthResolveFilter :: (self: *MTLRenderPassDepthAttachmentDescriptor, depthResolveFilter: MTLMultisampleDepthResolveFilter) -> () {
        _func: (obj: *void, selector: *void, depthResolveFilter: MTLMultisampleDepthResolveFilter) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setDepthResolveFilter_, depthResolveFilter);
    }

}

using MTLMultisampleStencilResolveFilter :: enum NSUInteger {
    MTLMultisampleStencilResolveFilterSample0 :: 0;
    MTLMultisampleStencilResolveFilterDepthResolvedSample :: 1;
}



MTLRenderPassStencilAttachmentDescriptor :: struct {
    mtlrenderpassattachmentdescriptor: MTLRenderPassAttachmentDescriptor;
    clearStencil :: (self: *MTLRenderPassStencilAttachmentDescriptor) -> uint32_t {
        _func: (obj: *void, selector: *void) -> uint32_t #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.clearStencil);
    }

    setClearStencil :: (self: *MTLRenderPassStencilAttachmentDescriptor, clearStencil: uint32_t) -> () {
        _func: (obj: *void, selector: *void, clearStencil: uint32_t) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setClearStencil_, clearStencil);
    }

    stencilResolveFilter :: (self: *MTLRenderPassStencilAttachmentDescriptor) -> MTLMultisampleStencilResolveFilter {
        _func: (obj: *void, selector: *void) -> MTLMultisampleStencilResolveFilter #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.stencilResolveFilter);
    }

    setStencilResolveFilter :: (self: *MTLRenderPassStencilAttachmentDescriptor, stencilResolveFilter: MTLMultisampleStencilResolveFilter) -> () {
        _func: (obj: *void, selector: *void, stencilResolveFilter: MTLMultisampleStencilResolveFilter) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setStencilResolveFilter_, stencilResolveFilter);
    }

}

MTLRenderPassColorAttachmentDescriptorArray :: struct {
    nsobject: NSObject;
    objectAtIndexedSubscript :: (self: *MTLRenderPassColorAttachmentDescriptorArray, attachmentIndex: NSUInteger) -> *MTLRenderPassColorAttachmentDescriptor {
        _func: (obj: *void, selector: *void, attachmentIndex: NSUInteger) -> *MTLRenderPassColorAttachmentDescriptor #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.objectAtIndexedSubscript_, attachmentIndex);
    }

    setObject_atIndexedSubscript :: (self: *MTLRenderPassColorAttachmentDescriptorArray, attachment: *MTLRenderPassColorAttachmentDescriptor, attachmentIndex: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, attachment: *MTLRenderPassColorAttachmentDescriptor, attachmentIndex: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setObject_atIndexedSubscript_, attachment, attachmentIndex);
    }

}

MTLRenderPassDescriptor :: struct {
    nsobject: NSObject;
    renderPassDescriptor :: () -> *MTLRenderPassDescriptor {
        _func: (obj: *void, selector: *void) -> *MTLRenderPassDescriptor #c_call;
        _func = xx objc_msgSend;
        return _func(objc_getClass("MTLRenderPassDescriptor"), __selectors.renderPassDescriptor);
    }

    setSamplePositions_count :: (self: *MTLRenderPassDescriptor, positions: *MTLSamplePosition, count: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, positions: *MTLSamplePosition, count: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setSamplePositions_count_, positions, count);
    }

    getSamplePositions_count :: (self: *MTLRenderPassDescriptor, positions: *MTLSamplePosition, count: NSUInteger) -> NSUInteger {
        _func: (obj: *void, selector: *void, positions: *MTLSamplePosition, count: NSUInteger) -> NSUInteger #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.getSamplePositions_count_, positions, count);
    }

    colorAttachments :: (self: *MTLRenderPassDescriptor) -> *MTLRenderPassColorAttachmentDescriptorArray {
        _func: (obj: *void, selector: *void) -> *MTLRenderPassColorAttachmentDescriptorArray #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.colorAttachments);
    }

    depthAttachment :: (self: *MTLRenderPassDescriptor) -> *MTLRenderPassDepthAttachmentDescriptor {
        _func: (obj: *void, selector: *void) -> *MTLRenderPassDepthAttachmentDescriptor #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.depthAttachment);
    }

    setDepthAttachment :: (self: *MTLRenderPassDescriptor, depthAttachment: *MTLRenderPassDepthAttachmentDescriptor) -> () {
        _func: (obj: *void, selector: *void, depthAttachment: *MTLRenderPassDepthAttachmentDescriptor) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setDepthAttachment_, depthAttachment);
    }

    stencilAttachment :: (self: *MTLRenderPassDescriptor) -> *MTLRenderPassStencilAttachmentDescriptor {
        _func: (obj: *void, selector: *void) -> *MTLRenderPassStencilAttachmentDescriptor #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.stencilAttachment);
    }

    setStencilAttachment :: (self: *MTLRenderPassDescriptor, stencilAttachment: *MTLRenderPassStencilAttachmentDescriptor) -> () {
        _func: (obj: *void, selector: *void, stencilAttachment: *MTLRenderPassStencilAttachmentDescriptor) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setStencilAttachment_, stencilAttachment);
    }

    visibilityResultBuffer :: (self: *MTLRenderPassDescriptor) -> id {
        _func: (obj: *void, selector: *void) -> id #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.visibilityResultBuffer);
    }

    setVisibilityResultBuffer :: (self: *MTLRenderPassDescriptor, visibilityResultBuffer: id) -> () {
        _func: (obj: *void, selector: *void, visibilityResultBuffer: id) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setVisibilityResultBuffer_, visibilityResultBuffer);
    }

    renderTargetArrayLength :: (self: *MTLRenderPassDescriptor) -> NSUInteger {
        _func: (obj: *void, selector: *void) -> NSUInteger #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.renderTargetArrayLength);
    }

    setRenderTargetArrayLength :: (self: *MTLRenderPassDescriptor, renderTargetArrayLength: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, renderTargetArrayLength: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setRenderTargetArrayLength_, renderTargetArrayLength);
    }

}

MTLClearColorMake :: (red: float64, green: float64, blue: float64, alpha: float64) -> MTLClearColor {
    col: MTLClearColor = ---;
    col.red = red;
    col.green = green;
    col.blue = blue;
    col.alpha = alpha;
    return col;
}

using MTLAttributeFormat :: enum NSUInteger {
    MTLAttributeFormatInvalid :: 0;
    MTLAttributeFormatUChar2 :: 1;
    MTLAttributeFormatUChar3 :: 2;
    MTLAttributeFormatUChar4 :: 3;
    MTLAttributeFormatChar2 :: 4;
    MTLAttributeFormatChar3 :: 5;
    MTLAttributeFormatChar4 :: 6;
    MTLAttributeFormatUChar2Normalized :: 7;
    MTLAttributeFormatUChar3Normalized :: 8;
    MTLAttributeFormatUChar4Normalized :: 9;
    MTLAttributeFormatChar2Normalized :: 10;
    MTLAttributeFormatChar3Normalized :: 11;
    MTLAttributeFormatChar4Normalized :: 12;
    MTLAttributeFormatUShort2 :: 13;
    MTLAttributeFormatUShort3 :: 14;
    MTLAttributeFormatUShort4 :: 15;
    MTLAttributeFormatShort2 :: 16;
    MTLAttributeFormatShort3 :: 17;
    MTLAttributeFormatShort4 :: 18;
    MTLAttributeFormatUShort2Normalized :: 19;
    MTLAttributeFormatUShort3Normalized :: 20;
    MTLAttributeFormatUShort4Normalized :: 21;
    MTLAttributeFormatShort2Normalized :: 22;
    MTLAttributeFormatShort3Normalized :: 23;
    MTLAttributeFormatShort4Normalized :: 24;
    MTLAttributeFormatHalf2 :: 25;
    MTLAttributeFormatHalf3 :: 26;
    MTLAttributeFormatHalf4 :: 27;
    MTLAttributeFormatFloat :: 28;
    MTLAttributeFormatFloat2 :: 29;
    MTLAttributeFormatFloat3 :: 30;
    MTLAttributeFormatFloat4 :: 31;
    MTLAttributeFormatInt :: 32;
    MTLAttributeFormatInt2 :: 33;
    MTLAttributeFormatInt3 :: 34;
    MTLAttributeFormatInt4 :: 35;
    MTLAttributeFormatUInt :: 36;
    MTLAttributeFormatUInt2 :: 37;
    MTLAttributeFormatUInt3 :: 38;
    MTLAttributeFormatUInt4 :: 39;
    MTLAttributeFormatInt1010102Normalized :: 40;
    MTLAttributeFormatUInt1010102Normalized :: 41;
    MTLAttributeFormatUChar4Normalized_BGRA :: 42;
    MTLAttributeFormatUChar :: 45;
    MTLAttributeFormatChar :: 46;
    MTLAttributeFormatUCharNormalized :: 47;
    MTLAttributeFormatCharNormalized :: 48;
    MTLAttributeFormatUShort :: 49;
    MTLAttributeFormatShort :: 50;
    MTLAttributeFormatUShortNormalized :: 51;
    MTLAttributeFormatShortNormalized :: 52;
    MTLAttributeFormatHalf :: 53;
}



using MTLIndexType :: enum NSUInteger {
    MTLIndexTypeUInt16 :: 0;
    MTLIndexTypeUInt32 :: 1;
}



using MTLStepFunction :: enum NSUInteger {
    MTLStepFunctionConstant :: 0;
    MTLStepFunctionPerVertex :: 1;
    MTLStepFunctionPerInstance :: 2;
    MTLStepFunctionPerPatch :: 3;
    MTLStepFunctionPerPatchControlPoint :: 4;
    MTLStepFunctionThreadPositionInGridX :: 5;
    MTLStepFunctionThreadPositionInGridY :: 6;
    MTLStepFunctionThreadPositionInGridXIndexed :: 7;
    MTLStepFunctionThreadPositionInGridYIndexed :: 8;
}



MTLBufferLayoutDescriptor :: struct {
    nsobject: NSObject;
    stride :: (self: *MTLBufferLayoutDescriptor) -> NSUInteger {
        _func: (obj: *void, selector: *void) -> NSUInteger #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.stride);
    }

    setStride :: (self: *MTLBufferLayoutDescriptor, stride: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, stride: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setStride_, stride);
    }

    stepFunction :: (self: *MTLBufferLayoutDescriptor) -> MTLStepFunction {
        _func: (obj: *void, selector: *void) -> MTLStepFunction #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.stepFunction);
    }

    setStepFunction :: (self: *MTLBufferLayoutDescriptor, stepFunction: MTLStepFunction) -> () {
        _func: (obj: *void, selector: *void, stepFunction: MTLStepFunction) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setStepFunction_, stepFunction);
    }

    stepRate :: (self: *MTLBufferLayoutDescriptor) -> NSUInteger {
        _func: (obj: *void, selector: *void) -> NSUInteger #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.stepRate);
    }

    setStepRate :: (self: *MTLBufferLayoutDescriptor, stepRate: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, stepRate: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setStepRate_, stepRate);
    }

}

MTLBufferLayoutDescriptorArray :: struct {
    nsobject: NSObject;
    objectAtIndexedSubscript :: (self: *MTLBufferLayoutDescriptorArray, index: NSUInteger) -> *MTLBufferLayoutDescriptor {
        _func: (obj: *void, selector: *void, index: NSUInteger) -> *MTLBufferLayoutDescriptor #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.objectAtIndexedSubscript_, index);
    }

    setObject_atIndexedSubscript :: (self: *MTLBufferLayoutDescriptorArray, bufferDesc: *MTLBufferLayoutDescriptor, index: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, bufferDesc: *MTLBufferLayoutDescriptor, index: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setObject_atIndexedSubscript_, bufferDesc, index);
    }

}

MTLAttributeDescriptor :: struct {
    nsobject: NSObject;
    format :: (self: *MTLAttributeDescriptor) -> MTLAttributeFormat {
        _func: (obj: *void, selector: *void) -> MTLAttributeFormat #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.format);
    }

    setFormat :: (self: *MTLAttributeDescriptor, format: MTLAttributeFormat) -> () {
        _func: (obj: *void, selector: *void, format: MTLAttributeFormat) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setFormat_, format);
    }

    offset :: (self: *MTLAttributeDescriptor) -> NSUInteger {
        _func: (obj: *void, selector: *void) -> NSUInteger #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.offset);
    }

    setOffset :: (self: *MTLAttributeDescriptor, offset: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, offset: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setOffset_, offset);
    }

    bufferIndex :: (self: *MTLAttributeDescriptor) -> NSUInteger {
        _func: (obj: *void, selector: *void) -> NSUInteger #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.bufferIndex);
    }

    setBufferIndex :: (self: *MTLAttributeDescriptor, bufferIndex: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, bufferIndex: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setBufferIndex_, bufferIndex);
    }

}

MTLAttributeDescriptorArray :: struct {
    nsobject: NSObject;
    objectAtIndexedSubscript :: (self: *MTLAttributeDescriptorArray, index: NSUInteger) -> *MTLAttributeDescriptor {
        _func: (obj: *void, selector: *void, index: NSUInteger) -> *MTLAttributeDescriptor #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.objectAtIndexedSubscript_, index);
    }

    setObject_atIndexedSubscript :: (self: *MTLAttributeDescriptorArray, attributeDesc: *MTLAttributeDescriptor, index: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, attributeDesc: *MTLAttributeDescriptor, index: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setObject_atIndexedSubscript_, attributeDesc, index);
    }

}

MTLStageInputOutputDescriptor :: struct {
    nsobject: NSObject;
    stageInputOutputDescriptor :: () -> *MTLStageInputOutputDescriptor {
        _func: (obj: *void, selector: *void) -> *MTLStageInputOutputDescriptor #c_call;
        _func = xx objc_msgSend;
        return _func(objc_getClass("MTLStageInputOutputDescriptor"), __selectors.stageInputOutputDescriptor);
    }

    reset :: (self: *MTLStageInputOutputDescriptor) -> () {
        _func: (obj: *void, selector: *void) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.reset);
    }

    layouts :: (self: *MTLStageInputOutputDescriptor) -> *MTLBufferLayoutDescriptorArray {
        _func: (obj: *void, selector: *void) -> *MTLBufferLayoutDescriptorArray #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.layouts);
    }

    attributes :: (self: *MTLStageInputOutputDescriptor) -> *MTLAttributeDescriptorArray {
        _func: (obj: *void, selector: *void) -> *MTLAttributeDescriptorArray #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.attributes);
    }

    indexType :: (self: *MTLStageInputOutputDescriptor) -> MTLIndexType {
        _func: (obj: *void, selector: *void) -> MTLIndexType #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.indexType);
    }

    setIndexType :: (self: *MTLStageInputOutputDescriptor, indexType: MTLIndexType) -> () {
        _func: (obj: *void, selector: *void, indexType: MTLIndexType) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setIndexType_, indexType);
    }

    indexBufferIndex :: (self: *MTLStageInputOutputDescriptor) -> NSUInteger {
        _func: (obj: *void, selector: *void) -> NSUInteger #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.indexBufferIndex);
    }

    setIndexBufferIndex :: (self: *MTLStageInputOutputDescriptor, indexBufferIndex: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, indexBufferIndex: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setIndexBufferIndex_, indexBufferIndex);
    }

}

using MTLMutability :: enum NSUInteger {
    MTLMutabilityDefault :: 0;
    MTLMutabilityMutable :: 1;
    MTLMutabilityImmutable :: 2;
}



MTLPipelineBufferDescriptor :: struct {
    nsobject: NSObject;
    mutability :: (self: *MTLPipelineBufferDescriptor) -> MTLMutability {
        _func: (obj: *void, selector: *void) -> MTLMutability #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.mutability);
    }

    setMutability :: (self: *MTLPipelineBufferDescriptor, mutability: MTLMutability) -> () {
        _func: (obj: *void, selector: *void, mutability: MTLMutability) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setMutability_, mutability);
    }

}

MTLPipelineBufferDescriptorArray :: struct {
    nsobject: NSObject;
    objectAtIndexedSubscript :: (self: *MTLPipelineBufferDescriptorArray, bufferIndex: NSUInteger) -> *MTLPipelineBufferDescriptor {
        _func: (obj: *void, selector: *void, bufferIndex: NSUInteger) -> *MTLPipelineBufferDescriptor #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.objectAtIndexedSubscript_, bufferIndex);
    }

    setObject_atIndexedSubscript :: (self: *MTLPipelineBufferDescriptorArray, buffer: *MTLPipelineBufferDescriptor, bufferIndex: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, buffer: *MTLPipelineBufferDescriptor, bufferIndex: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setObject_atIndexedSubscript_, buffer, bufferIndex);
    }

}

MTLComputePipelineReflection :: struct {
    nsobject: NSObject;
    arguments :: (self: *MTLComputePipelineReflection) -> *NSArray(*MTLArgument) {
        _func: (obj: *void, selector: *void) -> *NSArray(*MTLArgument) #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.arguments);
    }

}

MTLComputePipelineDescriptor :: struct {
    nsobject: NSObject;
    reset :: (self: *MTLComputePipelineDescriptor) -> () {
        _func: (obj: *void, selector: *void) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.reset);
    }

    label :: (self: *MTLComputePipelineDescriptor) -> *NSString {
        _func: (obj: *void, selector: *void) -> *NSString #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.label);
    }

    setLabel :: (self: *MTLComputePipelineDescriptor, label: *NSString) -> () {
        _func: (obj: *void, selector: *void, label: *NSString) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setLabel_, label);
    }

    computeFunction :: (self: *MTLComputePipelineDescriptor) -> id {
        _func: (obj: *void, selector: *void) -> id #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.computeFunction);
    }

    setComputeFunction :: (self: *MTLComputePipelineDescriptor, computeFunction: id) -> () {
        _func: (obj: *void, selector: *void, computeFunction: id) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setComputeFunction_, computeFunction);
    }

    threadGroupSizeIsMultipleOfThreadExecutionWidth :: (self: *MTLComputePipelineDescriptor) -> BOOL {
        _func: (obj: *void, selector: *void) -> BOOL #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.threadGroupSizeIsMultipleOfThreadExecutionWidth);
    }

    setThreadGroupSizeIsMultipleOfThreadExecutionWidth :: (self: *MTLComputePipelineDescriptor, threadGroupSizeIsMultipleOfThreadExecutionWidth: BOOL) -> () {
        _func: (obj: *void, selector: *void, threadGroupSizeIsMultipleOfThreadExecutionWidth: BOOL) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setThreadGroupSizeIsMultipleOfThreadExecutionWidth_, threadGroupSizeIsMultipleOfThreadExecutionWidth);
    }

    maxTotalThreadsPerThreadgroup :: (self: *MTLComputePipelineDescriptor) -> NSUInteger {
        _func: (obj: *void, selector: *void) -> NSUInteger #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.maxTotalThreadsPerThreadgroup);
    }

    setMaxTotalThreadsPerThreadgroup :: (self: *MTLComputePipelineDescriptor, maxTotalThreadsPerThreadgroup: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, maxTotalThreadsPerThreadgroup: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setMaxTotalThreadsPerThreadgroup_, maxTotalThreadsPerThreadgroup);
    }

    stageInputDescriptor :: (self: *MTLComputePipelineDescriptor) -> *MTLStageInputOutputDescriptor {
        _func: (obj: *void, selector: *void) -> *MTLStageInputOutputDescriptor #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.stageInputDescriptor);
    }

    setStageInputDescriptor :: (self: *MTLComputePipelineDescriptor, stageInputDescriptor: *MTLStageInputOutputDescriptor) -> () {
        _func: (obj: *void, selector: *void, stageInputDescriptor: *MTLStageInputOutputDescriptor) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setStageInputDescriptor_, stageInputDescriptor);
    }

    buffers :: (self: *MTLComputePipelineDescriptor) -> *MTLPipelineBufferDescriptorArray {
        _func: (obj: *void, selector: *void) -> *MTLPipelineBufferDescriptorArray #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.buffers);
    }

}

MTLComputePipelineState :: struct {
    label :: (self: *MTLComputePipelineState) -> *NSString {
        _func: (obj: *void, selector: *void) -> *NSString #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.label);
    }

    device :: (self: *MTLComputePipelineState) -> id {
        _func: (obj: *void, selector: *void) -> id #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.device);
    }

    maxTotalThreadsPerThreadgroup :: (self: *MTLComputePipelineState) -> NSUInteger {
        _func: (obj: *void, selector: *void) -> NSUInteger #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.maxTotalThreadsPerThreadgroup);
    }

    threadExecutionWidth :: (self: *MTLComputePipelineState) -> NSUInteger {
        _func: (obj: *void, selector: *void) -> NSUInteger #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.threadExecutionWidth);
    }

    staticThreadgroupMemoryLength :: (self: *MTLComputePipelineState) -> NSUInteger {
        _func: (obj: *void, selector: *void) -> NSUInteger #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.staticThreadgroupMemoryLength);
    }

}

using MTLPrimitiveType :: enum NSUInteger {
    MTLPrimitiveTypePoint :: 0;
    MTLPrimitiveTypeLine :: 1;
    MTLPrimitiveTypeLineStrip :: 2;
    MTLPrimitiveTypeTriangle :: 3;
    MTLPrimitiveTypeTriangleStrip :: 4;
}



using MTLVisibilityResultMode :: enum NSUInteger {
    MTLVisibilityResultModeDisabled :: 0;
    MTLVisibilityResultModeBoolean :: 1;
    MTLVisibilityResultModeCounting :: 2;
}



MTLScissorRect :: struct {
    x: NSUInteger;
    y: NSUInteger;
    width: NSUInteger;
    height: NSUInteger;
}

MTLViewport :: struct {
    originX: float64;
    originY: float64;
    width: float64;
    height: float64;
    znear: float64;
    zfar: float64;
}

using MTLCullMode :: enum NSUInteger {
    MTLCullModeNone :: 0;
    MTLCullModeFront :: 1;
    MTLCullModeBack :: 2;
}



using MTLWinding :: enum NSUInteger {
    MTLWindingClockwise :: 0;
    MTLWindingCounterClockwise :: 1;
}



using MTLDepthClipMode :: enum NSUInteger {
    MTLDepthClipModeClip :: 0;
    MTLDepthClipModeClamp :: 1;
}



using MTLTriangleFillMode :: enum NSUInteger {
    MTLTriangleFillModeFill :: 0;
    MTLTriangleFillModeLines :: 1;
}



MTLDrawPrimitivesIndirectArguments :: struct {
    vertexCount: uint32_t;
    instanceCount: uint32_t;
    vertexStart: uint32_t;
    baseInstance: uint32_t;
}

MTLDrawIndexedPrimitivesIndirectArguments :: struct {
    indexCount: uint32_t;
    instanceCount: uint32_t;
    indexStart: uint32_t;
    baseVertex: int32_t;
    baseInstance: uint32_t;
}

MTLDrawPatchIndirectArguments :: struct {
    patchCount: uint32_t;
    instanceCount: uint32_t;
    patchStart: uint32_t;
    baseInstance: uint32_t;
}

MTLQuadTessellationFactorsHalf :: struct {
    edgeTessellationFactor: [4] uint16_t;
    insideTessellationFactor: [2] uint16_t;
}

MTLTriangleTessellationFactorsHalf :: struct {
    edgeTessellationFactor: [3] uint16_t;
    insideTessellationFactor: uint16_t;
}

using MTLRenderStages :: enum NSUInteger {
    MTLRenderStageVertex :: 1;
    MTLRenderStageFragment :: 2;
}

MTLRenderCommandEncoder :: struct {
    using #as mtlcommandencder: MTLCommandEncoder;

    setRenderPipelineState :: (self: *MTLRenderCommandEncoder, pipelineState: id) -> () {
        _func: (obj: *void, selector: *void, pipelineState: id) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setRenderPipelineState_, pipelineState);
    }

    setVertexBytes_length_atIndex :: (self: *MTLRenderCommandEncoder, bytes: *void, length: NSUInteger, index: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, bytes: *void, length: NSUInteger, index: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setVertexBytes_length_atIndex_, bytes, length, index);
    }

    setVertexBuffer_offset_atIndex :: (self: *MTLRenderCommandEncoder, buffer: id, offset: NSUInteger, index: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, buffer: id, offset: NSUInteger, index: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setVertexBuffer_offset_atIndex_, buffer, offset, index);
    }

    setVertexBufferOffset_atIndex :: (self: *MTLRenderCommandEncoder, offset: NSUInteger, index: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, offset: NSUInteger, index: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setVertexBufferOffset_atIndex_, offset, index);
    }

    setVertexBuffers_offsets_withRange :: (self: *MTLRenderCommandEncoder, buffers: *id, offsets: *NSUInteger, range: NSRange) -> () {
        _func: (obj: *void, selector: *void, buffers: *id, offsets: *NSUInteger, range: NSRange) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setVertexBuffers_offsets_withRange_, buffers, offsets, range);
    }

    setVertexTexture_atIndex :: (self: *MTLRenderCommandEncoder, texture: id, index: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, texture: id, index: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setVertexTexture_atIndex_, texture, index);
    }

    setVertexTextures_withRange :: (self: *MTLRenderCommandEncoder, textures: *id, range: NSRange) -> () {
        _func: (obj: *void, selector: *void, textures: *id, range: NSRange) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setVertexTextures_withRange_, textures, range);
    }

    setVertexSamplerState_atIndex :: (self: *MTLRenderCommandEncoder, sampler: id, index: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, sampler: id, index: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setVertexSamplerState_atIndex_, sampler, index);
    }

    setVertexSamplerStates_withRange :: (self: *MTLRenderCommandEncoder, samplers: *id, range: NSRange) -> () {
        _func: (obj: *void, selector: *void, samplers: *id, range: NSRange) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setVertexSamplerStates_withRange_, samplers, range);
    }

    setVertexSamplerState_lodMinClamp_lodMaxClamp_atIndex :: (self: *MTLRenderCommandEncoder, sampler: id, lodMinClamp: float32, lodMaxClamp: float32, index: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, sampler: id, lodMinClamp: float32, lodMaxClamp: float32, index: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setVertexSamplerState_lodMinClamp_lodMaxClamp_atIndex_, sampler, lodMinClamp, lodMaxClamp, index);
    }

    setVertexSamplerStates_lodMinClamps_lodMaxClamps_withRange :: (self: *MTLRenderCommandEncoder, samplers: *id, lodMinClamps: *float32, lodMaxClamps: *float32, range: NSRange) -> () {
        _func: (obj: *void, selector: *void, samplers: *id, lodMinClamps: *float32, lodMaxClamps: *float32, range: NSRange) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setVertexSamplerStates_lodMinClamps_lodMaxClamps_withRange_, samplers, lodMinClamps, lodMaxClamps, range);
    }

    setViewport :: (self: *MTLRenderCommandEncoder, viewport: MTLViewport) -> () {
        _func: (obj: *void, selector: *void, viewport: MTLViewport) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setViewport_, viewport);
    }

    setViewports_count :: (self: *MTLRenderCommandEncoder, viewports: *MTLViewport, count: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, viewports: *MTLViewport, count: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setViewports_count_, viewports, count);
    }

    setFrontFacingWinding :: (self: *MTLRenderCommandEncoder, frontFacingWinding: MTLWinding) -> () {
        _func: (obj: *void, selector: *void, frontFacingWinding: MTLWinding) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setFrontFacingWinding_, frontFacingWinding);
    }

    setCullMode :: (self: *MTLRenderCommandEncoder, cullMode: MTLCullMode) -> () {
        _func: (obj: *void, selector: *void, cullMode: MTLCullMode) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setCullMode_, cullMode);
    }

    setDepthClipMode :: (self: *MTLRenderCommandEncoder, depthClipMode: MTLDepthClipMode) -> () {
        _func: (obj: *void, selector: *void, depthClipMode: MTLDepthClipMode) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setDepthClipMode_, depthClipMode);
    }

    setDepthBias_slopeScale_clamp :: (self: *MTLRenderCommandEncoder, depthBias: float32, slopeScale: float32, clamp: float32) -> () {
        _func: (obj: *void, selector: *void, depthBias: float32, slopeScale: float32, clamp: float32) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setDepthBias_slopeScale_clamp_, depthBias, slopeScale, clamp);
    }

    setScissorRect :: (self: *MTLRenderCommandEncoder, rect: MTLScissorRect) -> () {
        _func: (obj: *void, selector: *void, rect: MTLScissorRect) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setScissorRect_, rect);
    }

    setScissorRects_count :: (self: *MTLRenderCommandEncoder, scissorRects: *MTLScissorRect, count: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, scissorRects: *MTLScissorRect, count: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setScissorRects_count_, scissorRects, count);
    }

    setTriangleFillMode :: (self: *MTLRenderCommandEncoder, fillMode: MTLTriangleFillMode) -> () {
        _func: (obj: *void, selector: *void, fillMode: MTLTriangleFillMode) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setTriangleFillMode_, fillMode);
    }

    setFragmentBytes_length_atIndex :: (self: *MTLRenderCommandEncoder, bytes: *void, length: NSUInteger, index: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, bytes: *void, length: NSUInteger, index: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setFragmentBytes_length_atIndex_, bytes, length, index);
    }

    setFragmentBuffer_offset_atIndex :: (self: *MTLRenderCommandEncoder, buffer: id, offset: NSUInteger, index: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, buffer: id, offset: NSUInteger, index: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setFragmentBuffer_offset_atIndex_, buffer, offset, index);
    }

    setFragmentBufferOffset_atIndex :: (self: *MTLRenderCommandEncoder, offset: NSUInteger, index: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, offset: NSUInteger, index: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setFragmentBufferOffset_atIndex_, offset, index);
    }

    setFragmentBuffers_offsets_withRange :: (self: *MTLRenderCommandEncoder, buffers: *id, offsets: *NSUInteger, range: NSRange) -> () {
        _func: (obj: *void, selector: *void, buffers: *id, offsets: *NSUInteger, range: NSRange) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setFragmentBuffers_offsets_withRange_, buffers, offsets, range);
    }

    setFragmentTexture_atIndex :: (self: *MTLRenderCommandEncoder, texture: id, index: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, texture: id, index: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setFragmentTexture_atIndex_, texture, index);
    }

    setFragmentTextures_withRange :: (self: *MTLRenderCommandEncoder, textures: *id, range: NSRange) -> () {
        _func: (obj: *void, selector: *void, textures: *id, range: NSRange) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setFragmentTextures_withRange_, textures, range);
    }

    setFragmentSamplerState_atIndex :: (self: *MTLRenderCommandEncoder, sampler: id, index: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, sampler: id, index: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setFragmentSamplerState_atIndex_, sampler, index);
    }

    setFragmentSamplerStates_withRange :: (self: *MTLRenderCommandEncoder, samplers: *id, range: NSRange) -> () {
        _func: (obj: *void, selector: *void, samplers: *id, range: NSRange) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setFragmentSamplerStates_withRange_, samplers, range);
    }

    setFragmentSamplerState_lodMinClamp_lodMaxClamp_atIndex :: (self: *MTLRenderCommandEncoder, sampler: id, lodMinClamp: float32, lodMaxClamp: float32, index: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, sampler: id, lodMinClamp: float32, lodMaxClamp: float32, index: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setFragmentSamplerState_lodMinClamp_lodMaxClamp_atIndex_, sampler, lodMinClamp, lodMaxClamp, index);
    }

    setFragmentSamplerStates_lodMinClamps_lodMaxClamps_withRange :: (self: *MTLRenderCommandEncoder, samplers: *id, lodMinClamps: *float32, lodMaxClamps: *float32, range: NSRange) -> () {
        _func: (obj: *void, selector: *void, samplers: *id, lodMinClamps: *float32, lodMaxClamps: *float32, range: NSRange) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setFragmentSamplerStates_lodMinClamps_lodMaxClamps_withRange_, samplers, lodMinClamps, lodMaxClamps, range);
    }

    setBlendColorRed_green_blue_alpha :: (self: *MTLRenderCommandEncoder, red: float32, green: float32, blue: float32, alpha: float32) -> () {
        _func: (obj: *void, selector: *void, red: float32, green: float32, blue: float32, alpha: float32) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setBlendColorRed_green_blue_alpha_, red, green, blue, alpha);
    }

    setDepthStencilState :: (self: *MTLRenderCommandEncoder, depthStencilState: id) -> () {
        _func: (obj: *void, selector: *void, depthStencilState: id) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setDepthStencilState_, depthStencilState);
    }

    setStencilReferenceValue :: (self: *MTLRenderCommandEncoder, referenceValue: uint32_t) -> () {
        _func: (obj: *void, selector: *void, referenceValue: uint32_t) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setStencilReferenceValue_, referenceValue);
    }

    setStencilFrontReferenceValue_backReferenceValue :: (self: *MTLRenderCommandEncoder, frontReferenceValue: uint32_t, backReferenceValue: uint32_t) -> () {
        _func: (obj: *void, selector: *void, frontReferenceValue: uint32_t, backReferenceValue: uint32_t) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setStencilFrontReferenceValue_backReferenceValue_, frontReferenceValue, backReferenceValue);
    }

    setVisibilityResultMode_offset :: (self: *MTLRenderCommandEncoder, mode: MTLVisibilityResultMode, offset: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, mode: MTLVisibilityResultMode, offset: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setVisibilityResultMode_offset_, mode, offset);
    }

    setColorStoreAction_atIndex :: (self: *MTLRenderCommandEncoder, storeAction: MTLStoreAction, colorAttachmentIndex: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, storeAction: MTLStoreAction, colorAttachmentIndex: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setColorStoreAction_atIndex_, storeAction, colorAttachmentIndex);
    }

    setDepthStoreAction :: (self: *MTLRenderCommandEncoder, storeAction: MTLStoreAction) -> () {
        _func: (obj: *void, selector: *void, storeAction: MTLStoreAction) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setDepthStoreAction_, storeAction);
    }

    setStencilStoreAction :: (self: *MTLRenderCommandEncoder, storeAction: MTLStoreAction) -> () {
        _func: (obj: *void, selector: *void, storeAction: MTLStoreAction) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setStencilStoreAction_, storeAction);
    }

    setColorStoreActionOptions_atIndex :: (self: *MTLRenderCommandEncoder, storeActionOptions: MTLStoreActionOptions, colorAttachmentIndex: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, storeActionOptions: MTLStoreActionOptions, colorAttachmentIndex: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setColorStoreActionOptions_atIndex_, storeActionOptions, colorAttachmentIndex);
    }

    setDepthStoreActionOptions :: (self: *MTLRenderCommandEncoder, storeActionOptions: MTLStoreActionOptions) -> () {
        _func: (obj: *void, selector: *void, storeActionOptions: MTLStoreActionOptions) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setDepthStoreActionOptions_, storeActionOptions);
    }

    setStencilStoreActionOptions :: (self: *MTLRenderCommandEncoder, storeActionOptions: MTLStoreActionOptions) -> () {
        _func: (obj: *void, selector: *void, storeActionOptions: MTLStoreActionOptions) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setStencilStoreActionOptions_, storeActionOptions);
    }

    drawPrimitives_vertexStart_vertexCount_instanceCount :: (self: *MTLRenderCommandEncoder, primitiveType: MTLPrimitiveType, vertexStart: NSUInteger, vertexCount: NSUInteger, instanceCount: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, primitiveType: MTLPrimitiveType, vertexStart: NSUInteger, vertexCount: NSUInteger, instanceCount: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.drawPrimitives_vertexStart_vertexCount_instanceCount_, primitiveType, vertexStart, vertexCount, instanceCount);
    }

    drawPrimitives_vertexStart_vertexCount :: (self: *MTLRenderCommandEncoder, primitiveType: MTLPrimitiveType, vertexStart: NSUInteger, vertexCount: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, primitiveType: MTLPrimitiveType, vertexStart: NSUInteger, vertexCount: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.drawPrimitives_vertexStart_vertexCount_, primitiveType, vertexStart, vertexCount);
    }

    drawIndexedPrimitives_indexCount_indexType_indexBuffer_indexBufferOffset_instanceCount :: (self: *MTLRenderCommandEncoder, primitiveType: MTLPrimitiveType, indexCount: NSUInteger, indexType: MTLIndexType, indexBuffer: id, indexBufferOffset: NSUInteger, instanceCount: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, primitiveType: MTLPrimitiveType, indexCount: NSUInteger, indexType: MTLIndexType, indexBuffer: id, indexBufferOffset: NSUInteger, instanceCount: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.drawIndexedPrimitives_indexCount_indexType_indexBuffer_indexBufferOffset_instanceCount_, primitiveType, indexCount, indexType, indexBuffer, indexBufferOffset, instanceCount);
    }

    drawIndexedPrimitives_indexCount_indexType_indexBuffer_indexBufferOffset :: (self: *MTLRenderCommandEncoder, primitiveType: MTLPrimitiveType, indexCount: NSUInteger, indexType: MTLIndexType, indexBuffer: id, indexBufferOffset: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, primitiveType: MTLPrimitiveType, indexCount: NSUInteger, indexType: MTLIndexType, indexBuffer: id, indexBufferOffset: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.drawIndexedPrimitives_indexCount_indexType_indexBuffer_indexBufferOffset_, primitiveType, indexCount, indexType, indexBuffer, indexBufferOffset);
    }

    drawPrimitives_vertexStart_vertexCount_instanceCount_baseInstance :: (self: *MTLRenderCommandEncoder, primitiveType: MTLPrimitiveType, vertexStart: NSUInteger, vertexCount: NSUInteger, instanceCount: NSUInteger, baseInstance: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, primitiveType: MTLPrimitiveType, vertexStart: NSUInteger, vertexCount: NSUInteger, instanceCount: NSUInteger, baseInstance: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.drawPrimitives_vertexStart_vertexCount_instanceCount_baseInstance_, primitiveType, vertexStart, vertexCount, instanceCount, baseInstance);
    }

    drawIndexedPrimitives_indexCount_indexType_indexBuffer_indexBufferOffset_instanceCount_baseVertex_baseInstance :: (self: *MTLRenderCommandEncoder, primitiveType: MTLPrimitiveType, indexCount: NSUInteger, indexType: MTLIndexType, indexBuffer: id, indexBufferOffset: NSUInteger, instanceCount: NSUInteger, baseVertex: NSInteger, baseInstance: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, primitiveType: MTLPrimitiveType, indexCount: NSUInteger, indexType: MTLIndexType, indexBuffer: id, indexBufferOffset: NSUInteger, instanceCount: NSUInteger, baseVertex: NSInteger, baseInstance: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.drawIndexedPrimitives_indexCount_indexType_indexBuffer_indexBufferOffset_instanceCount_baseVertex_baseInstance_, primitiveType, indexCount, indexType, indexBuffer, indexBufferOffset, instanceCount, baseVertex, baseInstance);
    }

    drawPrimitives_indirectBuffer_indirectBufferOffset :: (self: *MTLRenderCommandEncoder, primitiveType: MTLPrimitiveType, indirectBuffer: id, indirectBufferOffset: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, primitiveType: MTLPrimitiveType, indirectBuffer: id, indirectBufferOffset: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.drawPrimitives_indirectBuffer_indirectBufferOffset_, primitiveType, indirectBuffer, indirectBufferOffset);
    }

    drawIndexedPrimitives_indexType_indexBuffer_indexBufferOffset_indirectBuffer_indirectBufferOffset :: (self: *MTLRenderCommandEncoder, primitiveType: MTLPrimitiveType, indexType: MTLIndexType, indexBuffer: id, indexBufferOffset: NSUInteger, indirectBuffer: id, indirectBufferOffset: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, primitiveType: MTLPrimitiveType, indexType: MTLIndexType, indexBuffer: id, indexBufferOffset: NSUInteger, indirectBuffer: id, indirectBufferOffset: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.drawIndexedPrimitives_indexType_indexBuffer_indexBufferOffset_indirectBuffer_indirectBufferOffset_, primitiveType, indexType, indexBuffer, indexBufferOffset, indirectBuffer, indirectBufferOffset);
    }

    textureBarrier :: (self: *MTLRenderCommandEncoder) -> () {
        _func: (obj: *void, selector: *void) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.textureBarrier);
    }

    updateFence_afterStages :: (self: *MTLRenderCommandEncoder, fence: id, stages: MTLRenderStages) -> () {
        _func: (obj: *void, selector: *void, fence: id, stages: MTLRenderStages) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.updateFence_afterStages_, fence, stages);
    }

    waitForFence_beforeStages :: (self: *MTLRenderCommandEncoder, fence: id, stages: MTLRenderStages) -> () {
        _func: (obj: *void, selector: *void, fence: id, stages: MTLRenderStages) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.waitForFence_beforeStages_, fence, stages);
    }

    setTessellationFactorBuffer_offset_instanceStride :: (self: *MTLRenderCommandEncoder, buffer: id, offset: NSUInteger, instanceStride: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, buffer: id, offset: NSUInteger, instanceStride: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setTessellationFactorBuffer_offset_instanceStride_, buffer, offset, instanceStride);
    }

    setTessellationFactorScale :: (self: *MTLRenderCommandEncoder, scale: float32) -> () {
        _func: (obj: *void, selector: *void, scale: float32) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setTessellationFactorScale_, scale);
    }

    drawPatches_patchStart_patchCount_patchIndexBuffer_patchIndexBufferOffset_instanceCount_baseInstance :: (self: *MTLRenderCommandEncoder, numberOfPatchControlPoints: NSUInteger, patchStart: NSUInteger, patchCount: NSUInteger, patchIndexBuffer: id, patchIndexBufferOffset: NSUInteger, instanceCount: NSUInteger, baseInstance: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, numberOfPatchControlPoints: NSUInteger, patchStart: NSUInteger, patchCount: NSUInteger, patchIndexBuffer: id, patchIndexBufferOffset: NSUInteger, instanceCount: NSUInteger, baseInstance: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.drawPatches_patchStart_patchCount_patchIndexBuffer_patchIndexBufferOffset_instanceCount_baseInstance_, numberOfPatchControlPoints, patchStart, patchCount, patchIndexBuffer, patchIndexBufferOffset, instanceCount, baseInstance);
    }

    drawPatches_patchIndexBuffer_patchIndexBufferOffset_indirectBuffer_indirectBufferOffset :: (self: *MTLRenderCommandEncoder, numberOfPatchControlPoints: NSUInteger, patchIndexBuffer: id, patchIndexBufferOffset: NSUInteger, indirectBuffer: id, indirectBufferOffset: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, numberOfPatchControlPoints: NSUInteger, patchIndexBuffer: id, patchIndexBufferOffset: NSUInteger, indirectBuffer: id, indirectBufferOffset: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.drawPatches_patchIndexBuffer_patchIndexBufferOffset_indirectBuffer_indirectBufferOffset_, numberOfPatchControlPoints, patchIndexBuffer, patchIndexBufferOffset, indirectBuffer, indirectBufferOffset);
    }

    drawIndexedPatches_patchStart_patchCount_patchIndexBuffer_patchIndexBufferOffset_controlPointIndexBuffer_controlPointIndexBufferOffset_instanceCount_baseInstance :: (self: *MTLRenderCommandEncoder, numberOfPatchControlPoints: NSUInteger, patchStart: NSUInteger, patchCount: NSUInteger, patchIndexBuffer: id, patchIndexBufferOffset: NSUInteger, controlPointIndexBuffer: id, controlPointIndexBufferOffset: NSUInteger, instanceCount: NSUInteger, baseInstance: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, numberOfPatchControlPoints: NSUInteger, patchStart: NSUInteger, patchCount: NSUInteger, patchIndexBuffer: id, patchIndexBufferOffset: NSUInteger, controlPointIndexBuffer: id, controlPointIndexBufferOffset: NSUInteger, instanceCount: NSUInteger, baseInstance: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.drawIndexedPatches_patchStart_patchCount_patchIndexBuffer_patchIndexBufferOffset_controlPointIndexBuffer_controlPointIndexBufferOffset_instanceCount_baseInstance_, numberOfPatchControlPoints, patchStart, patchCount, patchIndexBuffer, patchIndexBufferOffset, controlPointIndexBuffer, controlPointIndexBufferOffset, instanceCount, baseInstance);
    }

    drawIndexedPatches_patchIndexBuffer_patchIndexBufferOffset_controlPointIndexBuffer_controlPointIndexBufferOffset_indirectBuffer_indirectBufferOffset :: (self: *MTLRenderCommandEncoder, numberOfPatchControlPoints: NSUInteger, patchIndexBuffer: id, patchIndexBufferOffset: NSUInteger, controlPointIndexBuffer: id, controlPointIndexBufferOffset: NSUInteger, indirectBuffer: id, indirectBufferOffset: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, numberOfPatchControlPoints: NSUInteger, patchIndexBuffer: id, patchIndexBufferOffset: NSUInteger, controlPointIndexBuffer: id, controlPointIndexBufferOffset: NSUInteger, indirectBuffer: id, indirectBufferOffset: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.drawIndexedPatches_patchIndexBuffer_patchIndexBufferOffset_controlPointIndexBuffer_controlPointIndexBufferOffset_indirectBuffer_indirectBufferOffset_, numberOfPatchControlPoints, patchIndexBuffer, patchIndexBufferOffset, controlPointIndexBuffer, controlPointIndexBufferOffset, indirectBuffer, indirectBufferOffset);
    }

    useResource_usage :: (self: *MTLRenderCommandEncoder, resource: id, usage: MTLResourceUsage) -> () {
        _func: (obj: *void, selector: *void, resource: id, usage: MTLResourceUsage) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.useResource_usage_, resource, usage);
    }

    useResources_count_usage :: (self: *MTLRenderCommandEncoder, resources: *id, count: NSUInteger, usage: MTLResourceUsage) -> () {
        _func: (obj: *void, selector: *void, resources: *id, count: NSUInteger, usage: MTLResourceUsage) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.useResources_count_usage_, resources, count, usage);
    }

    useHeap :: (self: *MTLRenderCommandEncoder, heap: id) -> () {
        _func: (obj: *void, selector: *void, heap: id) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.useHeap_, heap);
    }

    useHeaps_count :: (self: *MTLRenderCommandEncoder, heaps: *id, count: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, heaps: *id, count: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.useHeaps_count_, heaps, count);
    }

    executeCommandsInBuffer_withRange :: (self: *MTLRenderCommandEncoder, indirectCommandBuffer: id, executionRange: NSRange) -> () {
        _func: (obj: *void, selector: *void, indirectCommandBuffer: id, executionRange: NSRange) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.executeCommandsInBuffer_withRange_, indirectCommandBuffer, executionRange);
    }

    executeCommandsInBuffer_indirectBuffer_indirectBufferOffset :: (self: *MTLRenderCommandEncoder, indirectCommandbuffer: id, indirectRangeBuffer: id, indirectBufferOffset: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, indirectCommandbuffer: id, indirectRangeBuffer: id, indirectBufferOffset: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.executeCommandsInBuffer_indirectBuffer_indirectBufferOffset_, indirectCommandbuffer, indirectRangeBuffer, indirectBufferOffset);
    }

    memoryBarrierWithScope_afterStages_beforeStages :: (self: *MTLRenderCommandEncoder, scope: MTLBarrierScope, after: MTLRenderStages, before: MTLRenderStages) -> () {
        _func: (obj: *void, selector: *void, scope: MTLBarrierScope, after: MTLRenderStages, before: MTLRenderStages) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.memoryBarrierWithScope_afterStages_beforeStages_, scope, after, before);
    }

    memoryBarrierWithResources_count_afterStages_beforeStages :: (self: *MTLRenderCommandEncoder, resources: *id, count: NSUInteger, after: MTLRenderStages, before: MTLRenderStages) -> () {
        _func: (obj: *void, selector: *void, resources: *id, count: NSUInteger, after: MTLRenderStages, before: MTLRenderStages) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.memoryBarrierWithResources_count_afterStages_beforeStages_, resources, count, after, before);
    }

}

MTLFunctionConstantValues :: struct {
    nsobject: NSObject;
    setConstantValue_type_atIndex :: (self: *MTLFunctionConstantValues, value: *void, type: MTLDataType, index: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, value: *void, type: MTLDataType, index: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setConstantValue_type_atIndex_, value, type, index);
    }

    setConstantValues_type_withRange :: (self: *MTLFunctionConstantValues, values: *void, type: MTLDataType, range: NSRange) -> () {
        _func: (obj: *void, selector: *void, values: *void, type: MTLDataType, range: NSRange) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setConstantValues_type_withRange_, values, type, range);
    }

    setConstantValue_type_withName :: (self: *MTLFunctionConstantValues, value: *void, type: MTLDataType, name: *NSString) -> () {
        _func: (obj: *void, selector: *void, value: *void, type: MTLDataType, name: *NSString) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setConstantValue_type_withName_, value, type, name);
    }

    reset :: (self: *MTLFunctionConstantValues) -> () {
        _func: (obj: *void, selector: *void) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.reset);
    }

}

using MTLBlendFactor :: enum NSUInteger {
    MTLBlendFactorZero :: 0;
    MTLBlendFactorOne :: 1;
    MTLBlendFactorSourceColor :: 2;
    MTLBlendFactorOneMinusSourceColor :: 3;
    MTLBlendFactorSourceAlpha :: 4;
    MTLBlendFactorOneMinusSourceAlpha :: 5;
    MTLBlendFactorDestinationColor :: 6;
    MTLBlendFactorOneMinusDestinationColor :: 7;
    MTLBlendFactorDestinationAlpha :: 8;
    MTLBlendFactorOneMinusDestinationAlpha :: 9;
    MTLBlendFactorSourceAlphaSaturated :: 10;
    MTLBlendFactorBlendColor :: 11;
    MTLBlendFactorOneMinusBlendColor :: 12;
    MTLBlendFactorBlendAlpha :: 13;
    MTLBlendFactorOneMinusBlendAlpha :: 14;
    MTLBlendFactorSource1Color :: 15;
    MTLBlendFactorOneMinusSource1Color :: 16;
    MTLBlendFactorSource1Alpha :: 17;
    MTLBlendFactorOneMinusSource1Alpha :: 18;
}



using MTLBlendOperation :: enum NSUInteger {
    MTLBlendOperationAdd :: 0;
    MTLBlendOperationSubtract :: 1;
    MTLBlendOperationReverseSubtract :: 2;
    MTLBlendOperationMin :: 3;
    MTLBlendOperationMax :: 4;
}



using MTLColorWriteMask :: enum NSUInteger {
    MTLColorWriteMaskNone :: 0;
    MTLColorWriteMaskRed :: 8;
    MTLColorWriteMaskGreen :: 4;
    MTLColorWriteMaskBlue :: 2;
    MTLColorWriteMaskAlpha :: 1;
    MTLColorWriteMaskAll :: 15;
}



using MTLPrimitiveTopologyClass :: enum NSUInteger {
    MTLPrimitiveTopologyClassUnspecified :: 0;
    MTLPrimitiveTopologyClassPoint :: 1;
    MTLPrimitiveTopologyClassLine :: 2;
    MTLPrimitiveTopologyClassTriangle :: 3;
}



using MTLTessellationPartitionMode :: enum NSUInteger {
    MTLTessellationPartitionModePow2 :: 0;
    MTLTessellationPartitionModeInteger :: 1;
    MTLTessellationPartitionModeFractionalOdd :: 2;
    MTLTessellationPartitionModeFractionalEven :: 3;
}



using MTLTessellationFactorStepFunction :: enum NSUInteger {
    MTLTessellationFactorStepFunctionConstant :: 0;
    MTLTessellationFactorStepFunctionPerPatch :: 1;
    MTLTessellationFactorStepFunctionPerInstance :: 2;
    MTLTessellationFactorStepFunctionPerPatchAndPerInstance :: 3;
}



using MTLTessellationFactorFormat :: enum NSUInteger {
    MTLTessellationFactorFormatHalf :: 0;
}



using MTLTessellationControlPointIndexType :: enum NSUInteger {
    MTLTessellationControlPointIndexTypeNone :: 0;
    MTLTessellationControlPointIndexTypeUInt16 :: 1;
    MTLTessellationControlPointIndexTypeUInt32 :: 2;
}



MTLRenderPipelineColorAttachmentDescriptor :: struct {
    nsobject: NSObject;
    pixelFormat :: (self: *MTLRenderPipelineColorAttachmentDescriptor) -> MTLPixelFormat {
        _func: (obj: *void, selector: *void) -> MTLPixelFormat #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.pixelFormat);
    }

    setPixelFormat :: (self: *MTLRenderPipelineColorAttachmentDescriptor, pixelFormat: MTLPixelFormat) -> () {
        _func: (obj: *void, selector: *void, pixelFormat: MTLPixelFormat) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setPixelFormat_, pixelFormat);
    }

    isBlendingEnabled :: (self: *MTLRenderPipelineColorAttachmentDescriptor) -> BOOL {
        _func: (obj: *void, selector: *void) -> BOOL #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.isBlendingEnabled);
    }

    setBlendingEnabled :: (self: *MTLRenderPipelineColorAttachmentDescriptor, blendingEnabled: BOOL) -> () {
        _func: (obj: *void, selector: *void, blendingEnabled: BOOL) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setBlendingEnabled_, blendingEnabled);
    }

    sourceRGBBlendFactor :: (self: *MTLRenderPipelineColorAttachmentDescriptor) -> MTLBlendFactor {
        _func: (obj: *void, selector: *void) -> MTLBlendFactor #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.sourceRGBBlendFactor);
    }

    setSourceRGBBlendFactor :: (self: *MTLRenderPipelineColorAttachmentDescriptor, sourceRGBBlendFactor: MTLBlendFactor) -> () {
        _func: (obj: *void, selector: *void, sourceRGBBlendFactor: MTLBlendFactor) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setSourceRGBBlendFactor_, sourceRGBBlendFactor);
    }

    destinationRGBBlendFactor :: (self: *MTLRenderPipelineColorAttachmentDescriptor) -> MTLBlendFactor {
        _func: (obj: *void, selector: *void) -> MTLBlendFactor #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.destinationRGBBlendFactor);
    }

    setDestinationRGBBlendFactor :: (self: *MTLRenderPipelineColorAttachmentDescriptor, destinationRGBBlendFactor: MTLBlendFactor) -> () {
        _func: (obj: *void, selector: *void, destinationRGBBlendFactor: MTLBlendFactor) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setDestinationRGBBlendFactor_, destinationRGBBlendFactor);
    }

    rgbBlendOperation :: (self: *MTLRenderPipelineColorAttachmentDescriptor) -> MTLBlendOperation {
        _func: (obj: *void, selector: *void) -> MTLBlendOperation #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.rgbBlendOperation);
    }

    setRgbBlendOperation :: (self: *MTLRenderPipelineColorAttachmentDescriptor, rgbBlendOperation: MTLBlendOperation) -> () {
        _func: (obj: *void, selector: *void, rgbBlendOperation: MTLBlendOperation) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setRgbBlendOperation_, rgbBlendOperation);
    }

    sourceAlphaBlendFactor :: (self: *MTLRenderPipelineColorAttachmentDescriptor) -> MTLBlendFactor {
        _func: (obj: *void, selector: *void) -> MTLBlendFactor #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.sourceAlphaBlendFactor);
    }

    setSourceAlphaBlendFactor :: (self: *MTLRenderPipelineColorAttachmentDescriptor, sourceAlphaBlendFactor: MTLBlendFactor) -> () {
        _func: (obj: *void, selector: *void, sourceAlphaBlendFactor: MTLBlendFactor) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setSourceAlphaBlendFactor_, sourceAlphaBlendFactor);
    }

    destinationAlphaBlendFactor :: (self: *MTLRenderPipelineColorAttachmentDescriptor) -> MTLBlendFactor {
        _func: (obj: *void, selector: *void) -> MTLBlendFactor #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.destinationAlphaBlendFactor);
    }

    setDestinationAlphaBlendFactor :: (self: *MTLRenderPipelineColorAttachmentDescriptor, destinationAlphaBlendFactor: MTLBlendFactor) -> () {
        _func: (obj: *void, selector: *void, destinationAlphaBlendFactor: MTLBlendFactor) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setDestinationAlphaBlendFactor_, destinationAlphaBlendFactor);
    }

    alphaBlendOperation :: (self: *MTLRenderPipelineColorAttachmentDescriptor) -> MTLBlendOperation {
        _func: (obj: *void, selector: *void) -> MTLBlendOperation #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.alphaBlendOperation);
    }

    setAlphaBlendOperation :: (self: *MTLRenderPipelineColorAttachmentDescriptor, alphaBlendOperation: MTLBlendOperation) -> () {
        _func: (obj: *void, selector: *void, alphaBlendOperation: MTLBlendOperation) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setAlphaBlendOperation_, alphaBlendOperation);
    }

    writeMask :: (self: *MTLRenderPipelineColorAttachmentDescriptor) -> MTLColorWriteMask {
        _func: (obj: *void, selector: *void) -> MTLColorWriteMask #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.writeMask);
    }

    setWriteMask :: (self: *MTLRenderPipelineColorAttachmentDescriptor, writeMask: MTLColorWriteMask) -> () {
        _func: (obj: *void, selector: *void, writeMask: MTLColorWriteMask) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setWriteMask_, writeMask);
    }

}

MTLRenderPipelineReflection :: struct {
    nsobject: NSObject;
    vertexArguments :: (self: *MTLRenderPipelineReflection) -> *NSArray(*MTLArgument) {
        _func: (obj: *void, selector: *void) -> *NSArray(*MTLArgument) #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.vertexArguments);
    }

    fragmentArguments :: (self: *MTLRenderPipelineReflection) -> *NSArray(*MTLArgument) {
        _func: (obj: *void, selector: *void) -> *NSArray(*MTLArgument) #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.fragmentArguments);
    }

}

MTLRenderPipelineDescriptor :: struct {
    nsobject: NSObject;
    reset :: (self: *MTLRenderPipelineDescriptor) -> () {
        _func: (obj: *void, selector: *void) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.reset);
    }

    label :: (self: *MTLRenderPipelineDescriptor) -> *NSString {
        _func: (obj: *void, selector: *void) -> *NSString #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.label);
    }

    setLabel :: (self: *MTLRenderPipelineDescriptor, label: *NSString) -> () {
        _func: (obj: *void, selector: *void, label: *NSString) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setLabel_, label);
    }

    vertexFunction :: (self: *MTLRenderPipelineDescriptor) -> id {
        _func: (obj: *void, selector: *void) -> id #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.vertexFunction);
    }

    setVertexFunction :: (self: *MTLRenderPipelineDescriptor, vertexFunction: id) -> () {
        _func: (obj: *void, selector: *void, vertexFunction: id) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setVertexFunction_, vertexFunction);
    }

    fragmentFunction :: (self: *MTLRenderPipelineDescriptor) -> id {
        _func: (obj: *void, selector: *void) -> id #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.fragmentFunction);
    }

    setFragmentFunction :: (self: *MTLRenderPipelineDescriptor, fragmentFunction: id) -> () {
        _func: (obj: *void, selector: *void, fragmentFunction: id) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setFragmentFunction_, fragmentFunction);
    }

    vertexDescriptor :: (self: *MTLRenderPipelineDescriptor) -> *MTLVertexDescriptor {
        _func: (obj: *void, selector: *void) -> *MTLVertexDescriptor #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.vertexDescriptor);
    }

    setVertexDescriptor :: (self: *MTLRenderPipelineDescriptor, vertexDescriptor: *MTLVertexDescriptor) -> () {
        _func: (obj: *void, selector: *void, vertexDescriptor: *MTLVertexDescriptor) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setVertexDescriptor_, vertexDescriptor);
    }

    sampleCount :: (self: *MTLRenderPipelineDescriptor) -> NSUInteger {
        _func: (obj: *void, selector: *void) -> NSUInteger #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.sampleCount);
    }

    setSampleCount :: (self: *MTLRenderPipelineDescriptor, sampleCount: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, sampleCount: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setSampleCount_, sampleCount);
    }

    rasterSampleCount :: (self: *MTLRenderPipelineDescriptor) -> NSUInteger {
        _func: (obj: *void, selector: *void) -> NSUInteger #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.rasterSampleCount);
    }

    setRasterSampleCount :: (self: *MTLRenderPipelineDescriptor, rasterSampleCount: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, rasterSampleCount: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setRasterSampleCount_, rasterSampleCount);
    }

    isAlphaToCoverageEnabled :: (self: *MTLRenderPipelineDescriptor) -> BOOL {
        _func: (obj: *void, selector: *void) -> BOOL #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.isAlphaToCoverageEnabled);
    }

    setAlphaToCoverageEnabled :: (self: *MTLRenderPipelineDescriptor, alphaToCoverageEnabled: BOOL) -> () {
        _func: (obj: *void, selector: *void, alphaToCoverageEnabled: BOOL) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setAlphaToCoverageEnabled_, alphaToCoverageEnabled);
    }

    isAlphaToOneEnabled :: (self: *MTLRenderPipelineDescriptor) -> BOOL {
        _func: (obj: *void, selector: *void) -> BOOL #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.isAlphaToOneEnabled);
    }

    setAlphaToOneEnabled :: (self: *MTLRenderPipelineDescriptor, alphaToOneEnabled: BOOL) -> () {
        _func: (obj: *void, selector: *void, alphaToOneEnabled: BOOL) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setAlphaToOneEnabled_, alphaToOneEnabled);
    }

    isRasterizationEnabled :: (self: *MTLRenderPipelineDescriptor) -> BOOL {
        _func: (obj: *void, selector: *void) -> BOOL #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.isRasterizationEnabled);
    }

    setRasterizationEnabled :: (self: *MTLRenderPipelineDescriptor, rasterizationEnabled: BOOL) -> () {
        _func: (obj: *void, selector: *void, rasterizationEnabled: BOOL) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setRasterizationEnabled_, rasterizationEnabled);
    }

    colorAttachments :: (self: *MTLRenderPipelineDescriptor) -> *MTLRenderPipelineColorAttachmentDescriptorArray {
        _func: (obj: *void, selector: *void) -> *MTLRenderPipelineColorAttachmentDescriptorArray #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.colorAttachments);
    }

    depthAttachmentPixelFormat :: (self: *MTLRenderPipelineDescriptor) -> MTLPixelFormat {
        _func: (obj: *void, selector: *void) -> MTLPixelFormat #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.depthAttachmentPixelFormat);
    }

    setDepthAttachmentPixelFormat :: (self: *MTLRenderPipelineDescriptor, depthAttachmentPixelFormat: MTLPixelFormat) -> () {
        _func: (obj: *void, selector: *void, depthAttachmentPixelFormat: MTLPixelFormat) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setDepthAttachmentPixelFormat_, depthAttachmentPixelFormat);
    }

    stencilAttachmentPixelFormat :: (self: *MTLRenderPipelineDescriptor) -> MTLPixelFormat {
        _func: (obj: *void, selector: *void) -> MTLPixelFormat #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.stencilAttachmentPixelFormat);
    }

    setStencilAttachmentPixelFormat :: (self: *MTLRenderPipelineDescriptor, stencilAttachmentPixelFormat: MTLPixelFormat) -> () {
        _func: (obj: *void, selector: *void, stencilAttachmentPixelFormat: MTLPixelFormat) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setStencilAttachmentPixelFormat_, stencilAttachmentPixelFormat);
    }

    inputPrimitiveTopology :: (self: *MTLRenderPipelineDescriptor) -> MTLPrimitiveTopologyClass {
        _func: (obj: *void, selector: *void) -> MTLPrimitiveTopologyClass #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.inputPrimitiveTopology);
    }

    setInputPrimitiveTopology :: (self: *MTLRenderPipelineDescriptor, inputPrimitiveTopology: MTLPrimitiveTopologyClass) -> () {
        _func: (obj: *void, selector: *void, inputPrimitiveTopology: MTLPrimitiveTopologyClass) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setInputPrimitiveTopology_, inputPrimitiveTopology);
    }

    tessellationPartitionMode :: (self: *MTLRenderPipelineDescriptor) -> MTLTessellationPartitionMode {
        _func: (obj: *void, selector: *void) -> MTLTessellationPartitionMode #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.tessellationPartitionMode);
    }

    setTessellationPartitionMode :: (self: *MTLRenderPipelineDescriptor, tessellationPartitionMode: MTLTessellationPartitionMode) -> () {
        _func: (obj: *void, selector: *void, tessellationPartitionMode: MTLTessellationPartitionMode) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setTessellationPartitionMode_, tessellationPartitionMode);
    }

    maxTessellationFactor :: (self: *MTLRenderPipelineDescriptor) -> NSUInteger {
        _func: (obj: *void, selector: *void) -> NSUInteger #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.maxTessellationFactor);
    }

    setMaxTessellationFactor :: (self: *MTLRenderPipelineDescriptor, maxTessellationFactor: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, maxTessellationFactor: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setMaxTessellationFactor_, maxTessellationFactor);
    }

    isTessellationFactorScaleEnabled :: (self: *MTLRenderPipelineDescriptor) -> BOOL {
        _func: (obj: *void, selector: *void) -> BOOL #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.isTessellationFactorScaleEnabled);
    }

    setTessellationFactorScaleEnabled :: (self: *MTLRenderPipelineDescriptor, tessellationFactorScaleEnabled: BOOL) -> () {
        _func: (obj: *void, selector: *void, tessellationFactorScaleEnabled: BOOL) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setTessellationFactorScaleEnabled_, tessellationFactorScaleEnabled);
    }

    tessellationFactorFormat :: (self: *MTLRenderPipelineDescriptor) -> MTLTessellationFactorFormat {
        _func: (obj: *void, selector: *void) -> MTLTessellationFactorFormat #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.tessellationFactorFormat);
    }

    setTessellationFactorFormat :: (self: *MTLRenderPipelineDescriptor, tessellationFactorFormat: MTLTessellationFactorFormat) -> () {
        _func: (obj: *void, selector: *void, tessellationFactorFormat: MTLTessellationFactorFormat) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setTessellationFactorFormat_, tessellationFactorFormat);
    }

    tessellationControlPointIndexType :: (self: *MTLRenderPipelineDescriptor) -> MTLTessellationControlPointIndexType {
        _func: (obj: *void, selector: *void) -> MTLTessellationControlPointIndexType #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.tessellationControlPointIndexType);
    }

    setTessellationControlPointIndexType :: (self: *MTLRenderPipelineDescriptor, tessellationControlPointIndexType: MTLTessellationControlPointIndexType) -> () {
        _func: (obj: *void, selector: *void, tessellationControlPointIndexType: MTLTessellationControlPointIndexType) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setTessellationControlPointIndexType_, tessellationControlPointIndexType);
    }

    tessellationFactorStepFunction :: (self: *MTLRenderPipelineDescriptor) -> MTLTessellationFactorStepFunction {
        _func: (obj: *void, selector: *void) -> MTLTessellationFactorStepFunction #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.tessellationFactorStepFunction);
    }

    setTessellationFactorStepFunction :: (self: *MTLRenderPipelineDescriptor, tessellationFactorStepFunction: MTLTessellationFactorStepFunction) -> () {
        _func: (obj: *void, selector: *void, tessellationFactorStepFunction: MTLTessellationFactorStepFunction) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setTessellationFactorStepFunction_, tessellationFactorStepFunction);
    }

    tessellationOutputWindingOrder :: (self: *MTLRenderPipelineDescriptor) -> MTLWinding {
        _func: (obj: *void, selector: *void) -> MTLWinding #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.tessellationOutputWindingOrder);
    }

    setTessellationOutputWindingOrder :: (self: *MTLRenderPipelineDescriptor, tessellationOutputWindingOrder: MTLWinding) -> () {
        _func: (obj: *void, selector: *void, tessellationOutputWindingOrder: MTLWinding) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setTessellationOutputWindingOrder_, tessellationOutputWindingOrder);
    }

    vertexBuffers :: (self: *MTLRenderPipelineDescriptor) -> *MTLPipelineBufferDescriptorArray {
        _func: (obj: *void, selector: *void) -> *MTLPipelineBufferDescriptorArray #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.vertexBuffers);
    }

    fragmentBuffers :: (self: *MTLRenderPipelineDescriptor) -> *MTLPipelineBufferDescriptorArray {
        _func: (obj: *void, selector: *void) -> *MTLPipelineBufferDescriptorArray #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.fragmentBuffers);
    }

    supportIndirectCommandBuffers :: (self: *MTLRenderPipelineDescriptor) -> BOOL {
        _func: (obj: *void, selector: *void) -> BOOL #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.supportIndirectCommandBuffers);
    }

    setSupportIndirectCommandBuffers :: (self: *MTLRenderPipelineDescriptor, supportIndirectCommandBuffers: BOOL) -> () {
        _func: (obj: *void, selector: *void, supportIndirectCommandBuffers: BOOL) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setSupportIndirectCommandBuffers_, supportIndirectCommandBuffers);
    }

}

MTLRenderPipelineState :: struct {
    label :: (self: *MTLRenderPipelineState) -> *NSString {
        _func: (obj: *void, selector: *void) -> *NSString #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.label);
    }

    device :: (self: *MTLRenderPipelineState) -> id {
        _func: (obj: *void, selector: *void) -> id #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.device);
    }

    supportIndirectCommandBuffers :: (self: *MTLRenderPipelineState) -> BOOL {
        _func: (obj: *void, selector: *void) -> BOOL #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.supportIndirectCommandBuffers);
    }

}

MTLRenderPipelineColorAttachmentDescriptorArray :: struct {
    nsobject: NSObject;
    objectAtIndexedSubscript :: (self: *MTLRenderPipelineColorAttachmentDescriptorArray, attachmentIndex: NSUInteger) -> *MTLRenderPipelineColorAttachmentDescriptor {
        _func: (obj: *void, selector: *void, attachmentIndex: NSUInteger) -> *MTLRenderPipelineColorAttachmentDescriptor #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.objectAtIndexedSubscript_, attachmentIndex);
    }

    setObject_atIndexedSubscript :: (self: *MTLRenderPipelineColorAttachmentDescriptorArray, attachment: *MTLRenderPipelineColorAttachmentDescriptor, attachmentIndex: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, attachment: *MTLRenderPipelineColorAttachmentDescriptor, attachmentIndex: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setObject_atIndexedSubscript_, attachment, attachmentIndex);
    }
}

using MTLVertexFormat :: enum NSUInteger {
    MTLVertexFormatInvalid :: 0;
    MTLVertexFormatUChar2 :: 1;
    MTLVertexFormatUChar3 :: 2;
    MTLVertexFormatUChar4 :: 3;
    MTLVertexFormatChar2 :: 4;
    MTLVertexFormatChar3 :: 5;
    MTLVertexFormatChar4 :: 6;
    MTLVertexFormatUChar2Normalized :: 7;
    MTLVertexFormatUChar3Normalized :: 8;
    MTLVertexFormatUChar4Normalized :: 9;
    MTLVertexFormatChar2Normalized :: 10;
    MTLVertexFormatChar3Normalized :: 11;
    MTLVertexFormatChar4Normalized :: 12;
    MTLVertexFormatUShort2 :: 13;
    MTLVertexFormatUShort3 :: 14;
    MTLVertexFormatUShort4 :: 15;
    MTLVertexFormatShort2 :: 16;
    MTLVertexFormatShort3 :: 17;
    MTLVertexFormatShort4 :: 18;
    MTLVertexFormatUShort2Normalized :: 19;
    MTLVertexFormatUShort3Normalized :: 20;
    MTLVertexFormatUShort4Normalized :: 21;
    MTLVertexFormatShort2Normalized :: 22;
    MTLVertexFormatShort3Normalized :: 23;
    MTLVertexFormatShort4Normalized :: 24;
    MTLVertexFormatHalf2 :: 25;
    MTLVertexFormatHalf3 :: 26;
    MTLVertexFormatHalf4 :: 27;
    MTLVertexFormatFloat :: 28;
    MTLVertexFormatFloat2 :: 29;
    MTLVertexFormatFloat3 :: 30;
    MTLVertexFormatFloat4 :: 31;
    MTLVertexFormatInt :: 32;
    MTLVertexFormatInt2 :: 33;
    MTLVertexFormatInt3 :: 34;
    MTLVertexFormatInt4 :: 35;
    MTLVertexFormatUInt :: 36;
    MTLVertexFormatUInt2 :: 37;
    MTLVertexFormatUInt3 :: 38;
    MTLVertexFormatUInt4 :: 39;
    MTLVertexFormatInt1010102Normalized :: 40;
    MTLVertexFormatUInt1010102Normalized :: 41;
    MTLVertexFormatUChar4Normalized_BGRA :: 42;
    MTLVertexFormatUChar :: 45;
    MTLVertexFormatChar :: 46;
    MTLVertexFormatUCharNormalized :: 47;
    MTLVertexFormatCharNormalized :: 48;
    MTLVertexFormatUShort :: 49;
    MTLVertexFormatShort :: 50;
    MTLVertexFormatUShortNormalized :: 51;
    MTLVertexFormatShortNormalized :: 52;
    MTLVertexFormatHalf :: 53;
}



using MTLVertexStepFunction :: enum NSUInteger {
    MTLVertexStepFunctionConstant :: 0;
    MTLVertexStepFunctionPerVertex :: 1;
    MTLVertexStepFunctionPerInstance :: 2;
    MTLVertexStepFunctionPerPatch :: 3;
    MTLVertexStepFunctionPerPatchControlPoint :: 4;
}



MTLVertexBufferLayoutDescriptor :: struct {
    nsobject: NSObject;
    stride :: (self: *MTLVertexBufferLayoutDescriptor) -> NSUInteger {
        _func: (obj: *void, selector: *void) -> NSUInteger #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.stride);
    }

    setStride :: (self: *MTLVertexBufferLayoutDescriptor, stride: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, stride: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setStride_, stride);
    }

    stepFunction :: (self: *MTLVertexBufferLayoutDescriptor) -> MTLVertexStepFunction {
        _func: (obj: *void, selector: *void) -> MTLVertexStepFunction #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.stepFunction);
    }

    setStepFunction :: (self: *MTLVertexBufferLayoutDescriptor, stepFunction: MTLVertexStepFunction) -> () {
        _func: (obj: *void, selector: *void, stepFunction: MTLVertexStepFunction) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setStepFunction_, stepFunction);
    }

    stepRate :: (self: *MTLVertexBufferLayoutDescriptor) -> NSUInteger {
        _func: (obj: *void, selector: *void) -> NSUInteger #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.stepRate);
    }

    setStepRate :: (self: *MTLVertexBufferLayoutDescriptor, stepRate: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, stepRate: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setStepRate_, stepRate);
    }

}

MTLVertexBufferLayoutDescriptorArray :: struct {
    nsobject: NSObject;
    objectAtIndexedSubscript :: (self: *MTLVertexBufferLayoutDescriptorArray, index: NSUInteger) -> *MTLVertexBufferLayoutDescriptor {
        _func: (obj: *void, selector: *void, index: NSUInteger) -> *MTLVertexBufferLayoutDescriptor #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.objectAtIndexedSubscript_, index);
    }

    setObject_atIndexedSubscript :: (self: *MTLVertexBufferLayoutDescriptorArray, bufferDesc: *MTLVertexBufferLayoutDescriptor, index: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, bufferDesc: *MTLVertexBufferLayoutDescriptor, index: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setObject_atIndexedSubscript_, bufferDesc, index);
    }

}

MTLVertexAttributeDescriptor :: struct {
    nsobject: NSObject;
    format :: (self: *MTLVertexAttributeDescriptor) -> MTLVertexFormat {
        _func: (obj: *void, selector: *void) -> MTLVertexFormat #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.format);
    }

    setFormat :: (self: *MTLVertexAttributeDescriptor, format: MTLVertexFormat) -> () {
        _func: (obj: *void, selector: *void, format: MTLVertexFormat) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setFormat_, format);
    }

    offset :: (self: *MTLVertexAttributeDescriptor) -> NSUInteger {
        _func: (obj: *void, selector: *void) -> NSUInteger #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.offset);
    }

    setOffset :: (self: *MTLVertexAttributeDescriptor, offset: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, offset: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setOffset_, offset);
    }

    bufferIndex :: (self: *MTLVertexAttributeDescriptor) -> NSUInteger {
        _func: (obj: *void, selector: *void) -> NSUInteger #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.bufferIndex);
    }

    setBufferIndex :: (self: *MTLVertexAttributeDescriptor, bufferIndex: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, bufferIndex: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setBufferIndex_, bufferIndex);
    }

}

MTLVertexAttributeDescriptorArray :: struct {
    nsobject: NSObject;
    objectAtIndexedSubscript :: (self: *MTLVertexAttributeDescriptorArray, index: NSUInteger) -> *MTLVertexAttributeDescriptor {
        _func: (obj: *void, selector: *void, index: NSUInteger) -> *MTLVertexAttributeDescriptor #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.objectAtIndexedSubscript_, index);
    }

    setObject_atIndexedSubscript :: (self: *MTLVertexAttributeDescriptorArray, attributeDesc: *MTLVertexAttributeDescriptor, index: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, attributeDesc: *MTLVertexAttributeDescriptor, index: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setObject_atIndexedSubscript_, attributeDesc, index);
    }

}

MTLVertexDescriptor :: struct {
    nsobject: NSObject;
    vertexDescriptor :: () -> *MTLVertexDescriptor {
        _func: (obj: *void, selector: *void) -> *MTLVertexDescriptor #c_call;
        _func = xx objc_msgSend;
        return _func(objc_getClass("MTLVertexDescriptor"), __selectors.vertexDescriptor);
    }

    reset :: (self: *MTLVertexDescriptor) -> () {
        _func: (obj: *void, selector: *void) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.reset);
    }

    layouts :: (self: *MTLVertexDescriptor) -> *MTLVertexBufferLayoutDescriptorArray {
        _func: (obj: *void, selector: *void) -> *MTLVertexBufferLayoutDescriptorArray #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.layouts);
    }

    attributes :: (self: *MTLVertexDescriptor) -> *MTLVertexAttributeDescriptorArray {
        _func: (obj: *void, selector: *void) -> *MTLVertexAttributeDescriptorArray #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.attributes);
    }

}

MTLParallelRenderCommandEncoder :: struct {
    renderCommandEncoder :: (self: *MTLParallelRenderCommandEncoder) -> id {
        _func: (obj: *void, selector: *void) -> id #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.renderCommandEncoder);
    }

    setColorStoreAction_atIndex :: (self: *MTLParallelRenderCommandEncoder, storeAction: MTLStoreAction, colorAttachmentIndex: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, storeAction: MTLStoreAction, colorAttachmentIndex: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setColorStoreAction_atIndex_, storeAction, colorAttachmentIndex);
    }

    setDepthStoreAction :: (self: *MTLParallelRenderCommandEncoder, storeAction: MTLStoreAction) -> () {
        _func: (obj: *void, selector: *void, storeAction: MTLStoreAction) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setDepthStoreAction_, storeAction);
    }

    setStencilStoreAction :: (self: *MTLParallelRenderCommandEncoder, storeAction: MTLStoreAction) -> () {
        _func: (obj: *void, selector: *void, storeAction: MTLStoreAction) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setStencilStoreAction_, storeAction);
    }

    setColorStoreActionOptions_atIndex :: (self: *MTLParallelRenderCommandEncoder, storeActionOptions: MTLStoreActionOptions, colorAttachmentIndex: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, storeActionOptions: MTLStoreActionOptions, colorAttachmentIndex: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setColorStoreActionOptions_atIndex_, storeActionOptions, colorAttachmentIndex);
    }

    setDepthStoreActionOptions :: (self: *MTLParallelRenderCommandEncoder, storeActionOptions: MTLStoreActionOptions) -> () {
        _func: (obj: *void, selector: *void, storeActionOptions: MTLStoreActionOptions) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setDepthStoreActionOptions_, storeActionOptions);
    }

    setStencilStoreActionOptions :: (self: *MTLParallelRenderCommandEncoder, storeActionOptions: MTLStoreActionOptions) -> () {
        _func: (obj: *void, selector: *void, storeActionOptions: MTLStoreActionOptions) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setStencilStoreActionOptions_, storeActionOptions);
    }

}

using MTLSamplerMinMagFilter :: enum NSUInteger {
    MTLSamplerMinMagFilterNearest :: 0;
    MTLSamplerMinMagFilterLinear :: 1;
}



using MTLSamplerMipFilter :: enum NSUInteger {
    MTLSamplerMipFilterNotMipmapped :: 0;
    MTLSamplerMipFilterNearest :: 1;
    MTLSamplerMipFilterLinear :: 2;
}



using MTLSamplerAddressMode :: enum NSUInteger {
    MTLSamplerAddressModeClampToEdge :: 0;
    MTLSamplerAddressModeMirrorClampToEdge :: 1;
    MTLSamplerAddressModeRepeat :: 2;
    MTLSamplerAddressModeMirrorRepeat :: 3;
    MTLSamplerAddressModeClampToZero :: 4;
    MTLSamplerAddressModeClampToBorderColor :: 5;
}



using MTLSamplerBorderColor :: enum NSUInteger {
    MTLSamplerBorderColorTransparentBlack :: 0;
    MTLSamplerBorderColorOpaqueBlack :: 1;
    MTLSamplerBorderColorOpaqueWhite :: 2;
}



MTLSamplerDescriptor :: struct {
    nsobject: NSObject;
    minFilter :: (self: *MTLSamplerDescriptor) -> MTLSamplerMinMagFilter {
        _func: (obj: *void, selector: *void) -> MTLSamplerMinMagFilter #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.minFilter);
    }

    setMinFilter :: (self: *MTLSamplerDescriptor, minFilter: MTLSamplerMinMagFilter) -> () {
        _func: (obj: *void, selector: *void, minFilter: MTLSamplerMinMagFilter) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setMinFilter_, minFilter);
    }

    magFilter :: (self: *MTLSamplerDescriptor) -> MTLSamplerMinMagFilter {
        _func: (obj: *void, selector: *void) -> MTLSamplerMinMagFilter #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.magFilter);
    }

    setMagFilter :: (self: *MTLSamplerDescriptor, magFilter: MTLSamplerMinMagFilter) -> () {
        _func: (obj: *void, selector: *void, magFilter: MTLSamplerMinMagFilter) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setMagFilter_, magFilter);
    }

    mipFilter :: (self: *MTLSamplerDescriptor) -> MTLSamplerMipFilter {
        _func: (obj: *void, selector: *void) -> MTLSamplerMipFilter #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.mipFilter);
    }

    setMipFilter :: (self: *MTLSamplerDescriptor, mipFilter: MTLSamplerMipFilter) -> () {
        _func: (obj: *void, selector: *void, mipFilter: MTLSamplerMipFilter) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setMipFilter_, mipFilter);
    }

    maxAnisotropy :: (self: *MTLSamplerDescriptor) -> NSUInteger {
        _func: (obj: *void, selector: *void) -> NSUInteger #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.maxAnisotropy);
    }

    setMaxAnisotropy :: (self: *MTLSamplerDescriptor, maxAnisotropy: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, maxAnisotropy: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setMaxAnisotropy_, maxAnisotropy);
    }

    sAddressMode :: (self: *MTLSamplerDescriptor) -> MTLSamplerAddressMode {
        _func: (obj: *void, selector: *void) -> MTLSamplerAddressMode #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.sAddressMode);
    }

    setSAddressMode :: (self: *MTLSamplerDescriptor, sAddressMode: MTLSamplerAddressMode) -> () {
        _func: (obj: *void, selector: *void, sAddressMode: MTLSamplerAddressMode) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setSAddressMode_, sAddressMode);
    }

    tAddressMode :: (self: *MTLSamplerDescriptor) -> MTLSamplerAddressMode {
        _func: (obj: *void, selector: *void) -> MTLSamplerAddressMode #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.tAddressMode);
    }

    setTAddressMode :: (self: *MTLSamplerDescriptor, tAddressMode: MTLSamplerAddressMode) -> () {
        _func: (obj: *void, selector: *void, tAddressMode: MTLSamplerAddressMode) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setTAddressMode_, tAddressMode);
    }

    rAddressMode :: (self: *MTLSamplerDescriptor) -> MTLSamplerAddressMode {
        _func: (obj: *void, selector: *void) -> MTLSamplerAddressMode #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.rAddressMode);
    }

    setRAddressMode :: (self: *MTLSamplerDescriptor, rAddressMode: MTLSamplerAddressMode) -> () {
        _func: (obj: *void, selector: *void, rAddressMode: MTLSamplerAddressMode) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setRAddressMode_, rAddressMode);
    }

    borderColor :: (self: *MTLSamplerDescriptor) -> MTLSamplerBorderColor {
        _func: (obj: *void, selector: *void) -> MTLSamplerBorderColor #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.borderColor);
    }

    setBorderColor :: (self: *MTLSamplerDescriptor, borderColor: MTLSamplerBorderColor) -> () {
        _func: (obj: *void, selector: *void, borderColor: MTLSamplerBorderColor) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setBorderColor_, borderColor);
    }

    normalizedCoordinates :: (self: *MTLSamplerDescriptor) -> BOOL {
        _func: (obj: *void, selector: *void) -> BOOL #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.normalizedCoordinates);
    }

    setNormalizedCoordinates :: (self: *MTLSamplerDescriptor, normalizedCoordinates: BOOL) -> () {
        _func: (obj: *void, selector: *void, normalizedCoordinates: BOOL) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setNormalizedCoordinates_, normalizedCoordinates);
    }

    lodMinClamp :: (self: *MTLSamplerDescriptor) -> float32 {
        _func: (obj: *void, selector: *void) -> float32 #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.lodMinClamp);
    }

    setLodMinClamp :: (self: *MTLSamplerDescriptor, lodMinClamp: float32) -> () {
        _func: (obj: *void, selector: *void, lodMinClamp: float32) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setLodMinClamp_, lodMinClamp);
    }

    lodMaxClamp :: (self: *MTLSamplerDescriptor) -> float32 {
        _func: (obj: *void, selector: *void) -> float32 #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.lodMaxClamp);
    }

    setLodMaxClamp :: (self: *MTLSamplerDescriptor, lodMaxClamp: float32) -> () {
        _func: (obj: *void, selector: *void, lodMaxClamp: float32) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setLodMaxClamp_, lodMaxClamp);
    }

    lodAverage :: (self: *MTLSamplerDescriptor) -> BOOL {
        _func: (obj: *void, selector: *void) -> BOOL #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.lodAverage);
    }

    setLodAverage :: (self: *MTLSamplerDescriptor, lodAverage: BOOL) -> () {
        _func: (obj: *void, selector: *void, lodAverage: BOOL) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setLodAverage_, lodAverage);
    }

    compareFunction :: (self: *MTLSamplerDescriptor) -> MTLCompareFunction {
        _func: (obj: *void, selector: *void) -> MTLCompareFunction #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.compareFunction);
    }

    setCompareFunction :: (self: *MTLSamplerDescriptor, compareFunction: MTLCompareFunction) -> () {
        _func: (obj: *void, selector: *void, compareFunction: MTLCompareFunction) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setCompareFunction_, compareFunction);
    }

    supportArgumentBuffers :: (self: *MTLSamplerDescriptor) -> BOOL {
        _func: (obj: *void, selector: *void) -> BOOL #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.supportArgumentBuffers);
    }

    setSupportArgumentBuffers :: (self: *MTLSamplerDescriptor, supportArgumentBuffers: BOOL) -> () {
        _func: (obj: *void, selector: *void, supportArgumentBuffers: BOOL) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setSupportArgumentBuffers_, supportArgumentBuffers);
    }

    label :: (self: *MTLSamplerDescriptor) -> *NSString {
        _func: (obj: *void, selector: *void) -> *NSString #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.label);
    }

    setLabel :: (self: *MTLSamplerDescriptor, label: *NSString) -> () {
        _func: (obj: *void, selector: *void, label: *NSString) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setLabel_, label);
    }

}

MTLSamplerState :: struct {
    label :: (self: *MTLSamplerState) -> *NSString {
        _func: (obj: *void, selector: *void) -> *NSString #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.label);
    }

    device :: (self: *MTLSamplerState) -> id {
        _func: (obj: *void, selector: *void) -> id #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.device);
    }

}

MTLHeapDescriptor :: struct {
    nsobject: NSObject;
    size :: (self: *MTLHeapDescriptor) -> NSUInteger {
        _func: (obj: *void, selector: *void) -> NSUInteger #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.size);
    }

    setSize :: (self: *MTLHeapDescriptor, size: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, size: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setSize_, size);
    }

    storageMode :: (self: *MTLHeapDescriptor) -> MTLStorageMode {
        _func: (obj: *void, selector: *void) -> MTLStorageMode #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.storageMode);
    }

    setStorageMode :: (self: *MTLHeapDescriptor, storageMode: MTLStorageMode) -> () {
        _func: (obj: *void, selector: *void, storageMode: MTLStorageMode) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setStorageMode_, storageMode);
    }

    cpuCacheMode :: (self: *MTLHeapDescriptor) -> MTLCPUCacheMode {
        _func: (obj: *void, selector: *void) -> MTLCPUCacheMode #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.cpuCacheMode);
    }

    setCpuCacheMode :: (self: *MTLHeapDescriptor, cpuCacheMode: MTLCPUCacheMode) -> () {
        _func: (obj: *void, selector: *void, cpuCacheMode: MTLCPUCacheMode) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setCpuCacheMode_, cpuCacheMode);
    }

}

MTLHeap :: struct {
    maxAvailableSizeWithAlignment :: (self: *MTLHeap, alignment: NSUInteger) -> NSUInteger {
        _func: (obj: *void, selector: *void, alignment: NSUInteger) -> NSUInteger #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.maxAvailableSizeWithAlignment_, alignment);
    }

    newBufferWithLength_options :: (self: *MTLHeap, length: NSUInteger, options: MTLResourceOptions) -> *MTLBuffer {
        _func: (obj: *void, selector: *void, length: NSUInteger, options: MTLResourceOptions) -> *MTLBuffer #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.newBufferWithLength_options_, length, options);
    }

    newTextureWithDescriptor :: (self: *MTLHeap, desc: *MTLTextureDescriptor) -> id {
        _func: (obj: *void, selector: *void, desc: *MTLTextureDescriptor) -> id #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.newTextureWithDescriptor_, desc);
    }

    setPurgeableState :: (self: *MTLHeap, state: MTLPurgeableState) -> MTLPurgeableState {
        _func: (obj: *void, selector: *void, state: MTLPurgeableState) -> MTLPurgeableState #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.setPurgeableState_, state);
    }

    label :: (self: *MTLHeap) -> *NSString {
        _func: (obj: *void, selector: *void) -> *NSString #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.label);
    }

    setLabel :: (self: *MTLHeap, label: *NSString) -> () {
        _func: (obj: *void, selector: *void, label: *NSString) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setLabel_, label);
    }

    device :: (self: *MTLHeap) -> id {
        _func: (obj: *void, selector: *void) -> id #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.device);
    }

    storageMode :: (self: *MTLHeap) -> MTLStorageMode {
        _func: (obj: *void, selector: *void) -> MTLStorageMode #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.storageMode);
    }

    cpuCacheMode :: (self: *MTLHeap) -> MTLCPUCacheMode {
        _func: (obj: *void, selector: *void) -> MTLCPUCacheMode #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.cpuCacheMode);
    }

    size :: (self: *MTLHeap) -> NSUInteger {
        _func: (obj: *void, selector: *void) -> NSUInteger #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.size);
    }

    usedSize :: (self: *MTLHeap) -> NSUInteger {
        _func: (obj: *void, selector: *void) -> NSUInteger #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.usedSize);
    }

    currentAllocatedSize :: (self: *MTLHeap) -> NSUInteger {
        _func: (obj: *void, selector: *void) -> NSUInteger #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.currentAllocatedSize);
    }

}

MTLArgumentEncoder :: struct {
    setArgumentBuffer_offset :: (self: *MTLArgumentEncoder, argumentBuffer: id, offset: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, argumentBuffer: id, offset: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setArgumentBuffer_offset_, argumentBuffer, offset);
    }

    setArgumentBuffer_startOffset_arrayElement :: (self: *MTLArgumentEncoder, argumentBuffer: id, startOffset: NSUInteger, arrayElement: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, argumentBuffer: id, startOffset: NSUInteger, arrayElement: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setArgumentBuffer_startOffset_arrayElement_, argumentBuffer, startOffset, arrayElement);
    }

    setBuffer_offset_atIndex :: (self: *MTLArgumentEncoder, buffer: id, offset: NSUInteger, index: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, buffer: id, offset: NSUInteger, index: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setBuffer_offset_atIndex_, buffer, offset, index);
    }

    setBuffers_offsets_withRange :: (self: *MTLArgumentEncoder, buffers: *id, offsets: *NSUInteger, range: NSRange) -> () {
        _func: (obj: *void, selector: *void, buffers: *id, offsets: *NSUInteger, range: NSRange) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setBuffers_offsets_withRange_, buffers, offsets, range);
    }

    setTexture_atIndex :: (self: *MTLArgumentEncoder, texture: id, index: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, texture: id, index: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setTexture_atIndex_, texture, index);
    }

    setTextures_withRange :: (self: *MTLArgumentEncoder, textures: *id, range: NSRange) -> () {
        _func: (obj: *void, selector: *void, textures: *id, range: NSRange) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setTextures_withRange_, textures, range);
    }

    setSamplerState_atIndex :: (self: *MTLArgumentEncoder, sampler: id, index: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, sampler: id, index: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setSamplerState_atIndex_, sampler, index);
    }

    setSamplerStates_withRange :: (self: *MTLArgumentEncoder, samplers: *id, range: NSRange) -> () {
        _func: (obj: *void, selector: *void, samplers: *id, range: NSRange) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setSamplerStates_withRange_, samplers, range);
    }

    constantDataAtIndex :: (self: *MTLArgumentEncoder, index: NSUInteger) -> *void {
        _func: (obj: *void, selector: *void, index: NSUInteger) -> *void #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.constantDataAtIndex_, index);
    }

    setRenderPipelineState_atIndex :: (self: *MTLArgumentEncoder, pipeline: id, index: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, pipeline: id, index: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setRenderPipelineState_atIndex_, pipeline, index);
    }

    setRenderPipelineStates_withRange :: (self: *MTLArgumentEncoder, pipelines: *id, range: NSRange) -> () {
        _func: (obj: *void, selector: *void, pipelines: *id, range: NSRange) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setRenderPipelineStates_withRange_, pipelines, range);
    }

    setIndirectCommandBuffer_atIndex :: (self: *MTLArgumentEncoder, indirectCommandBuffer: id, index: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, indirectCommandBuffer: id, index: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setIndirectCommandBuffer_atIndex_, indirectCommandBuffer, index);
    }

    setIndirectCommandBuffers_withRange :: (self: *MTLArgumentEncoder, buffers: *id, range: NSRange) -> () {
        _func: (obj: *void, selector: *void, buffers: *id, range: NSRange) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setIndirectCommandBuffers_withRange_, buffers, range);
    }

    newArgumentEncoderForBufferAtIndex :: (self: *MTLArgumentEncoder, index: NSUInteger) -> id {
        _func: (obj: *void, selector: *void, index: NSUInteger) -> id #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.newArgumentEncoderForBufferAtIndex_, index);
    }

    device :: (self: *MTLArgumentEncoder) -> id {
        _func: (obj: *void, selector: *void) -> id #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.device);
    }

    label :: (self: *MTLArgumentEncoder) -> *NSString {
        _func: (obj: *void, selector: *void) -> *NSString #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.label);
    }

    setLabel :: (self: *MTLArgumentEncoder, label: *NSString) -> () {
        _func: (obj: *void, selector: *void, label: *NSString) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setLabel_, label);
    }

    encodedLength :: (self: *MTLArgumentEncoder) -> NSUInteger {
        _func: (obj: *void, selector: *void) -> NSUInteger #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.encodedLength);
    }

    alignment :: (self: *MTLArgumentEncoder) -> NSUInteger {
        _func: (obj: *void, selector: *void) -> NSUInteger #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.alignment);
    }

}

MTLCaptureManager :: struct {
    nsobject: NSObject;
    _isCapturing: BOOL;
    _defaultCaptureScope: id;
    sharedCaptureManager :: () -> *MTLCaptureManager {
        _func: (obj: *void, selector: *void) -> *MTLCaptureManager #c_call;
        _func = xx objc_msgSend;
        return _func(objc_getClass("MTLCaptureManager"), __selectors.sharedCaptureManager);
    }

    init :: (self: *MTLCaptureManager) -> *MTLCaptureManager {
        _func: (obj: *void, selector: *void) -> *MTLCaptureManager #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.init);
    }

    newCaptureScopeWithDevice :: (self: *MTLCaptureManager, device: id) -> id {
        _func: (obj: *void, selector: *void, device: id) -> id #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.newCaptureScopeWithDevice_, device);
    }

    newCaptureScopeWithCommandQueue :: (self: *MTLCaptureManager, commandQueue: id) -> id {
        _func: (obj: *void, selector: *void, commandQueue: id) -> id #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.newCaptureScopeWithCommandQueue_, commandQueue);
    }

    startCaptureWithDevice :: (self: *MTLCaptureManager, device: id) -> () {
        _func: (obj: *void, selector: *void, device: id) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.startCaptureWithDevice_, device);
    }

    startCaptureWithCommandQueue :: (self: *MTLCaptureManager, commandQueue: id) -> () {
        _func: (obj: *void, selector: *void, commandQueue: id) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.startCaptureWithCommandQueue_, commandQueue);
    }

    startCaptureWithScope :: (self: *MTLCaptureManager, captureScope: id) -> () {
        _func: (obj: *void, selector: *void, captureScope: id) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.startCaptureWithScope_, captureScope);
    }

    stopCapture :: (self: *MTLCaptureManager) -> () {
        _func: (obj: *void, selector: *void) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.stopCapture);
    }

    defaultCaptureScope :: (self: *MTLCaptureManager) -> id {
        _func: (obj: *void, selector: *void) -> id #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.defaultCaptureScope);
    }

    setDefaultCaptureScope :: (self: *MTLCaptureManager, defaultCaptureScope: id) -> () {
        _func: (obj: *void, selector: *void, defaultCaptureScope: id) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setDefaultCaptureScope_, defaultCaptureScope);
    }

    isCapturing :: (self: *MTLCaptureManager) -> BOOL {
        _func: (obj: *void, selector: *void) -> BOOL #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.isCapturing);
    }

}

MTLCaptureScope :: struct {
    beginScope :: (self: *MTLCaptureScope) -> () {
        _func: (obj: *void, selector: *void) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.beginScope);
    }

    endScope :: (self: *MTLCaptureScope) -> () {
        _func: (obj: *void, selector: *void) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.endScope);
    }

    label :: (self: *MTLCaptureScope) -> *NSString {
        _func: (obj: *void, selector: *void) -> *NSString #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.label);
    }

    setLabel :: (self: *MTLCaptureScope, label: *NSString) -> () {
        _func: (obj: *void, selector: *void, label: *NSString) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setLabel_, label);
    }

    device :: (self: *MTLCaptureScope) -> id {
        _func: (obj: *void, selector: *void) -> id #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.device);
    }

    commandQueue :: (self: *MTLCaptureScope) -> id {
        _func: (obj: *void, selector: *void) -> id #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.commandQueue);
    }

}

MTLIndirectRenderCommand :: struct {
    setRenderPipelineState :: (self: *MTLIndirectRenderCommand, pipelineState: id) -> () {
        _func: (obj: *void, selector: *void, pipelineState: id) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setRenderPipelineState_, pipelineState);
    }

    setVertexBuffer_offset_atIndex :: (self: *MTLIndirectRenderCommand, buffer: id, offset: NSUInteger, index: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, buffer: id, offset: NSUInteger, index: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setVertexBuffer_offset_atIndex_, buffer, offset, index);
    }

    setFragmentBuffer_offset_atIndex :: (self: *MTLIndirectRenderCommand, buffer: id, offset: NSUInteger, index: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, buffer: id, offset: NSUInteger, index: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setFragmentBuffer_offset_atIndex_, buffer, offset, index);
    }

    drawPatches_patchStart_patchCount_patchIndexBuffer_patchIndexBufferOffset_instanceCount_baseInstance_tessellationFactorBuffer_tessellationFactorBufferOffset_tessellationFactorBufferInstanceStride :: (self: *MTLIndirectRenderCommand, numberOfPatchControlPoints: NSUInteger, patchStart: NSUInteger, patchCount: NSUInteger, patchIndexBuffer: id, patchIndexBufferOffset: NSUInteger, instanceCount: NSUInteger, baseInstance: NSUInteger, buffer: id, offset: NSUInteger, instanceStride: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, numberOfPatchControlPoints: NSUInteger, patchStart: NSUInteger, patchCount: NSUInteger, patchIndexBuffer: id, patchIndexBufferOffset: NSUInteger, instanceCount: NSUInteger, baseInstance: NSUInteger, buffer: id, offset: NSUInteger, instanceStride: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.drawPatches_patchStart_patchCount_patchIndexBuffer_patchIndexBufferOffset_instanceCount_baseInstance_tessellationFactorBuffer_tessellationFactorBufferOffset_tessellationFactorBufferInstanceStride_, numberOfPatchControlPoints, patchStart, patchCount, patchIndexBuffer, patchIndexBufferOffset, instanceCount, baseInstance, buffer, offset, instanceStride);
    }

    drawIndexedPatches_patchStart_patchCount_patchIndexBuffer_patchIndexBufferOffset_controlPointIndexBuffer_controlPointIndexBufferOffset_instanceCount_baseInstance_tessellationFactorBuffer_tessellationFactorBufferOffset_tessellationFactorBufferInstanceStride :: (self: *MTLIndirectRenderCommand, numberOfPatchControlPoints: NSUInteger, patchStart: NSUInteger, patchCount: NSUInteger, patchIndexBuffer: id, patchIndexBufferOffset: NSUInteger, controlPointIndexBuffer: id, controlPointIndexBufferOffset: NSUInteger, instanceCount: NSUInteger, baseInstance: NSUInteger, buffer: id, offset: NSUInteger, instanceStride: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, numberOfPatchControlPoints: NSUInteger, patchStart: NSUInteger, patchCount: NSUInteger, patchIndexBuffer: id, patchIndexBufferOffset: NSUInteger, controlPointIndexBuffer: id, controlPointIndexBufferOffset: NSUInteger, instanceCount: NSUInteger, baseInstance: NSUInteger, buffer: id, offset: NSUInteger, instanceStride: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.drawIndexedPatches_patchStart_patchCount_patchIndexBuffer_patchIndexBufferOffset_controlPointIndexBuffer_controlPointIndexBufferOffset_instanceCount_baseInstance_tessellationFactorBuffer_tessellationFactorBufferOffset_tessellationFactorBufferInstanceStride_, numberOfPatchControlPoints, patchStart, patchCount, patchIndexBuffer, patchIndexBufferOffset, controlPointIndexBuffer, controlPointIndexBufferOffset, instanceCount, baseInstance, buffer, offset, instanceStride);
    }

    drawPrimitives_vertexStart_vertexCount_instanceCount_baseInstance :: (self: *MTLIndirectRenderCommand, primitiveType: MTLPrimitiveType, vertexStart: NSUInteger, vertexCount: NSUInteger, instanceCount: NSUInteger, baseInstance: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, primitiveType: MTLPrimitiveType, vertexStart: NSUInteger, vertexCount: NSUInteger, instanceCount: NSUInteger, baseInstance: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.drawPrimitives_vertexStart_vertexCount_instanceCount_baseInstance_, primitiveType, vertexStart, vertexCount, instanceCount, baseInstance);
    }

    drawIndexedPrimitives_indexCount_indexType_indexBuffer_indexBufferOffset_instanceCount_baseVertex_baseInstance :: (self: *MTLIndirectRenderCommand, primitiveType: MTLPrimitiveType, indexCount: NSUInteger, indexType: MTLIndexType, indexBuffer: id, indexBufferOffset: NSUInteger, instanceCount: NSUInteger, baseVertex: NSInteger, baseInstance: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, primitiveType: MTLPrimitiveType, indexCount: NSUInteger, indexType: MTLIndexType, indexBuffer: id, indexBufferOffset: NSUInteger, instanceCount: NSUInteger, baseVertex: NSInteger, baseInstance: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.drawIndexedPrimitives_indexCount_indexType_indexBuffer_indexBufferOffset_instanceCount_baseVertex_baseInstance_, primitiveType, indexCount, indexType, indexBuffer, indexBufferOffset, instanceCount, baseVertex, baseInstance);
    }

    reset :: (self: *MTLIndirectRenderCommand) -> () {
        _func: (obj: *void, selector: *void) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.reset);
    }

}

using MTLIndirectCommandType :: enum NSUInteger {
    MTLIndirectCommandTypeDraw :: 1;
    MTLIndirectCommandTypeDrawIndexed :: 2;
    MTLIndirectCommandTypeDrawPatches :: 4;
    MTLIndirectCommandTypeDrawIndexedPatches :: 8;
}



MTLIndirectCommandBufferDescriptor :: struct {
    nsobject: NSObject;
    commandTypes :: (self: *MTLIndirectCommandBufferDescriptor) -> MTLIndirectCommandType {
        _func: (obj: *void, selector: *void) -> MTLIndirectCommandType #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.commandTypes);
    }

    setCommandTypes :: (self: *MTLIndirectCommandBufferDescriptor, commandTypes: MTLIndirectCommandType) -> () {
        _func: (obj: *void, selector: *void, commandTypes: MTLIndirectCommandType) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setCommandTypes_, commandTypes);
    }

    inheritPipelineState :: (self: *MTLIndirectCommandBufferDescriptor) -> BOOL {
        _func: (obj: *void, selector: *void) -> BOOL #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.inheritPipelineState);
    }

    setInheritPipelineState :: (self: *MTLIndirectCommandBufferDescriptor, inheritPipelineState: BOOL) -> () {
        _func: (obj: *void, selector: *void, inheritPipelineState: BOOL) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setInheritPipelineState_, inheritPipelineState);
    }

    inheritBuffers :: (self: *MTLIndirectCommandBufferDescriptor) -> BOOL {
        _func: (obj: *void, selector: *void) -> BOOL #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.inheritBuffers);
    }

    setInheritBuffers :: (self: *MTLIndirectCommandBufferDescriptor, inheritBuffers: BOOL) -> () {
        _func: (obj: *void, selector: *void, inheritBuffers: BOOL) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setInheritBuffers_, inheritBuffers);
    }

    maxVertexBufferBindCount :: (self: *MTLIndirectCommandBufferDescriptor) -> NSUInteger {
        _func: (obj: *void, selector: *void) -> NSUInteger #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.maxVertexBufferBindCount);
    }

    setMaxVertexBufferBindCount :: (self: *MTLIndirectCommandBufferDescriptor, maxVertexBufferBindCount: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, maxVertexBufferBindCount: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setMaxVertexBufferBindCount_, maxVertexBufferBindCount);
    }

    maxFragmentBufferBindCount :: (self: *MTLIndirectCommandBufferDescriptor) -> NSUInteger {
        _func: (obj: *void, selector: *void) -> NSUInteger #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.maxFragmentBufferBindCount);
    }

    setMaxFragmentBufferBindCount :: (self: *MTLIndirectCommandBufferDescriptor, maxFragmentBufferBindCount: NSUInteger) -> () {
        _func: (obj: *void, selector: *void, maxFragmentBufferBindCount: NSUInteger) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setMaxFragmentBufferBindCount_, maxFragmentBufferBindCount);
    }

}

MTLIndirectCommandBuffer :: struct {
    resetWithRange :: (self: *MTLIndirectCommandBuffer, range: NSRange) -> () {
        _func: (obj: *void, selector: *void, range: NSRange) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.resetWithRange_, range);
    }

    indirectRenderCommandAtIndex :: (self: *MTLIndirectCommandBuffer, commandIndex: NSUInteger) -> id {
        _func: (obj: *void, selector: *void, commandIndex: NSUInteger) -> id #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.indirectRenderCommandAtIndex_, commandIndex);
    }

    size :: (self: *MTLIndirectCommandBuffer) -> NSUInteger {
        _func: (obj: *void, selector: *void) -> NSUInteger #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.size);
    }

}

MTLEvent :: struct {
    device :: (self: *MTLEvent) -> id {
        _func: (obj: *void, selector: *void) -> id #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.device);
    }

    label :: (self: *MTLEvent) -> *NSString {
        _func: (obj: *void, selector: *void) -> *NSString #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.label);
    }

    setLabel :: (self: *MTLEvent, label: *NSString) -> () {
        _func: (obj: *void, selector: *void, label: *NSString) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setLabel_, label);
    }

}

MTLSharedEventListener :: struct {
    nsobject: NSObject;
    init :: (self: *MTLSharedEventListener) -> *MTLSharedEventListener {
        _func: (obj: *void, selector: *void) -> *MTLSharedEventListener #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.init);
    }

    initWithDispatchQueue :: (self: *MTLSharedEventListener, dispatchQueue: dispatch_queue_t) -> *MTLSharedEventListener {
        _func: (obj: *void, selector: *void, dispatchQueue: dispatch_queue_t) -> *MTLSharedEventListener #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.initWithDispatchQueue_, dispatchQueue);
    }

    dispatchQueue :: (self: *MTLSharedEventListener) -> dispatch_queue_t {
        _func: (obj: *void, selector: *void) -> dispatch_queue_t #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.dispatchQueue);
    }

}

MTLSharedEvent :: struct {
    newSharedEventHandle :: (self: *MTLSharedEvent) -> *MTLSharedEventHandle {
        _func: (obj: *void, selector: *void) -> *MTLSharedEventHandle #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.newSharedEventHandle);
    }

    signaledValue :: (self: *MTLSharedEvent) -> uint64_t {
        _func: (obj: *void, selector: *void) -> uint64_t #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.signaledValue);
    }

    setSignaledValue :: (self: *MTLSharedEvent, signaledValue: uint64_t) -> () {
        _func: (obj: *void, selector: *void, signaledValue: uint64_t) -> () #c_call;
        _func = xx objc_msgSend;
        _func(self, __selectors.setSignaledValue_, signaledValue);
    }

}

MTLSharedEventHandle :: struct {
    nsobject: NSObject;
    _priv: *MTLSharedEventHandlePrivate;
    label :: (self: *MTLSharedEventHandle) -> *NSString {
        _func: (obj: *void, selector: *void) -> *NSString #c_call;
        _func = xx objc_msgSend;
        return _func(self, __selectors.label);
    }

}

MTLSharedEventHandlePrivate :: struct {
}

#scope_file

Metal :: #library,system,link_always "Metal";  // We were having some problems on Mac, so, try this...

_Generated_Selectors :: struct #type_info_no_size_complaint {
    layer: *void = ---;
    nextDrawable: *void = ---;
    setDevice_: *void = ---;
    framebufferOnly: *void = ---;
    setFramebufferOnly_: *void = ---;
    drawableSize: *void = ---;
    setDrawableSize_: *void = ---;
    maximumDrawableCount: *void = ---;
    setMaximumDrawableCount_: *void = ---;
    presentsWithTransaction: *void = ---;
    setPresentsWithTransaction_: *void = ---;
    colorspace: *void = ---;
    setColorspace_: *void = ---;
    wantsExtendedDynamicRangeContent: *void = ---;
    setWantsExtendedDynamicRangeContent_: *void = ---;
    displaySyncEnabled: *void = ---;
    setDisplaySyncEnabled_: *void = ---;
    allowsNextDrawableTimeout: *void = ---;
    setAllowsNextDrawableTimeout_: *void = ---;


    endEncoding: *void = ---;
    insertDebugSignpost_: *void = ---;
    pushDebugGroup_: *void = ---;
    popDebugGroup: *void = ---;
    device: *void = ---;
    label: *void = ---;
    setLabel_: *void = ---;
    setPurgeableState_: *void = ---;
    makeAliasable: *void = ---;
    isAliasable: *void = ---;
    cpuCacheMode: *void = ---;
    storageMode: *void = ---;
    heap: *void = ---;
    allocatedSize: *void = ---;
    contents: *void = ---;
    didModifyRange_: *void = ---;
    newTextureWithDescriptor_offset_bytesPerRow_: *void = ---;
    addDebugMarker_range_: *void = ---;
    removeAllDebugMarkers: *void = ---;
    length: *void = ---;
    texture2DDescriptorWithPixelFormat_width_height_mipmapped_: *void = ---;
    textureCubeDescriptorWithPixelFormat_size_mipmapped_: *void = ---;
    textureBufferDescriptorWithPixelFormat_width_resourceOptions_usage_: *void = ---;
    textureType: *void = ---;
    setTextureType_: *void = ---;
    pixelFormat: *void = ---;
    setPixelFormat_: *void = ---;
    width: *void = ---;
    setWidth_: *void = ---;
    height: *void = ---;
    setHeight_: *void = ---;
    depth: *void = ---;
    setDepth_: *void = ---;
    mipmapLevelCount: *void = ---;
    setMipmapLevelCount_: *void = ---;
    sampleCount: *void = ---;
    setSampleCount_: *void = ---;
    arrayLength: *void = ---;
    setArrayLength_: *void = ---;
    resourceOptions: *void = ---;
    setResourceOptions_: *void = ---;
    setCpuCacheMode_: *void = ---;
    setStorageMode_: *void = ---;
    usage: *void = ---;
    setUsage_: *void = ---;
    allowGPUOptimizedContents: *void = ---;
    setAllowGPUOptimizedContents_: *void = ---;
    getBytes_bytesPerRow_bytesPerImage_fromRegion_mipmapLevel_slice_: *void = ---;
    replaceRegion_mipmapLevel_slice_withBytes_bytesPerRow_bytesPerImage_: *void = ---;
    getBytes_bytesPerRow_fromRegion_mipmapLevel_: *void = ---;
    replaceRegion_mipmapLevel_withBytes_bytesPerRow_: *void = ---;
    newTextureViewWithPixelFormat_: *void = ---;
    newTextureViewWithPixelFormat_textureType_levels_slices_: *void = ---;
    newSharedTextureHandle: *void = ---;
    rootResource: *void = ---;
    parentTexture: *void = ---;
    parentRelativeLevel: *void = ---;
    parentRelativeSlice: *void = ---;
    buffer: *void = ---;
    bufferOffset: *void = ---;
    bufferBytesPerRow: *void = ---;
    iosurface: *void = ---;
    iosurfacePlane: *void = ---;
    isShareable: *void = ---;
    isFramebufferOnly: *void = ---;
    dataType: *void = ---;
    structType: *void = ---;
    arrayType: *void = ---;
    textureReferenceType: *void = ---;
    pointerType: *void = ---;
    name: *void = ---;
    offset: *void = ---;
    argumentIndex: *void = ---;
    memberByName_: *void = ---;
    members: *void = ---;
    elementStructType: *void = ---;
    elementArrayType: *void = ---;
    elementTextureReferenceType: *void = ---;
    elementPointerType: *void = ---;
    elementType: *void = ---;
    stride: *void = ---;
    argumentIndexStride: *void = ---;
    access: *void = ---;
    alignment: *void = ---;
    dataSize: *void = ---;
    elementIsArgumentBuffer: *void = ---;
    textureDataType: *void = ---;
    isDepthTexture: *void = ---;
    type: *void = ---;
    index: *void = ---;
    isActive: *void = ---;
    bufferAlignment: *void = ---;
    bufferDataSize: *void = ---;
    bufferDataType: *void = ---;
    bufferStructType: *void = ---;
    bufferPointerType: *void = ---;
    threadgroupMemoryAlignment: *void = ---;
    threadgroupMemoryDataSize: *void = ---;
    attributeIndex: *void = ---;
    attributeType: *void = ---;
    isPatchData: *void = ---;
    isPatchControlPointData: *void = ---;
    required: *void = ---;
    newArgumentEncoderWithBufferIndex_: *void = ---;
    newArgumentEncoderWithBufferIndex_reflection_: *void = ---;
    functionType: *void = ---;
    patchType: *void = ---;
    patchControlPointCount: *void = ---;
    vertexAttributes: *void = ---;
    stageInputAttributes: *void = ---;
    functionConstantsDictionary: *void = ---;
    preprocessorMacros: *void = ---;
    setPreprocessorMacros_: *void = ---;
    fastMathEnabled: *void = ---;
    setFastMathEnabled_: *void = ---;
    languageVersion: *void = ---;
    setLanguageVersion_: *void = ---;
    newFunctionWithName_: *void = ---;
    newFunctionWithName_constantValues_error_: *void = ---;
    newFunctionWithName_constantValues_completionHandler_: *void = ---;
    functionNames: *void = ---;
    argumentDescriptor: *void = ---;
    setDataType_: *void = ---;
    setIndex_: *void = ---;
    setAccess_: *void = ---;
    constantBlockAlignment: *void = ---;
    setConstantBlockAlignment_: *void = ---;
    newCommandQueue: *void = ---;
    newCommandQueueWithMaxCommandBufferCount_: *void = ---;
    heapTextureSizeAndAlignWithDescriptor_: *void = ---;
    heapBufferSizeAndAlignWithLength_options_: *void = ---;
    newHeapWithDescriptor_: *void = ---;
    newBufferWithLength_options_: *void = ---;
    newBufferWithBytes_length_options_: *void = ---;
    newBufferWithBytesNoCopy_length_options_deallocator_: *void = ---;
    newDepthStencilStateWithDescriptor_: *void = ---;
    newTextureWithDescriptor_: *void = ---;
    newTextureWithDescriptor_iosurface_plane_: *void = ---;
    newSharedTextureWithDescriptor_: *void = ---;
    newSharedTextureWithHandle_: *void = ---;
    newSamplerStateWithDescriptor_: *void = ---;
    newDefaultLibrary: *void = ---;
    newDefaultLibraryWithBundle_error_: *void = ---;
    newLibraryWithFile_error_: *void = ---;
    newLibraryWithURL_error_: *void = ---;
    newLibraryWithData_error_: *void = ---;
    newLibraryWithSource_options_error_: *void = ---;
    newLibraryWithSource_options_completionHandler_: *void = ---;
    newRenderPipelineStateWithDescriptor_error_: *void = ---;
    newRenderPipelineStateWithDescriptor_options_reflection_error_: *void = ---;
    newRenderPipelineStateWithDescriptor_completionHandler_: *void = ---;
    newRenderPipelineStateWithDescriptor_options_completionHandler_: *void = ---;
    newComputePipelineStateWithFunction_error_: *void = ---;
    newComputePipelineStateWithFunction_options_reflection_error_: *void = ---;
    newComputePipelineStateWithFunction_completionHandler_: *void = ---;
    newComputePipelineStateWithFunction_options_completionHandler_: *void = ---;
    newComputePipelineStateWithDescriptor_options_reflection_error_: *void = ---;
    newComputePipelineStateWithDescriptor_options_completionHandler_: *void = ---;
    newFence: *void = ---;
    supportsFamily_: *void = ---;
    supportsFeatureSet_: *void = ---;
    supportsTextureSampleCount_: *void = ---;
    minimumLinearTextureAlignmentForPixelFormat_: *void = ---;
    minimumTextureBufferAlignmentForPixelFormat_: *void = ---;
    getDefaultSamplePositions_count_: *void = ---;
    newArgumentEncoderWithArguments_: *void = ---;
    newIndirectCommandBufferWithDescriptor_maxCommandCount_options_: *void = ---;
    newEvent: *void = ---;
    newSharedEvent: *void = ---;
    newSharedEventWithHandle_: *void = ---;
    registryID: *void = ---;
    maxThreadsPerThreadgroup: *void = ---;
    isLowPower: *void = ---;
    isHeadless: *void = ---;
    isRemovable: *void = ---;
    recommendedMaxWorkingSetSize: *void = ---;
    isDepth24Stencil8PixelFormatSupported: *void = ---;
    readWriteTextureSupport: *void = ---;
    argumentBuffersSupport: *void = ---;
    areRasterOrderGroupsSupported: *void = ---;
    currentAllocatedSize: *void = ---;
    maxThreadgroupMemoryLength: *void = ---;
    maxArgumentBufferSamplerCount: *void = ---;
    areProgrammableSamplePositionsSupported: *void = ---;
    maxBufferLength: *void = ---;
    synchronizeResource_: *void = ---;
    synchronizeTexture_slice_level_: *void = ---;
    copyFromTexture_sourceSlice_sourceLevel_sourceOrigin_sourceSize_toTexture_destinationSlice_destinationLevel_destinationOrigin_: *void = ---;
    copyFromBuffer_sourceOffset_sourceBytesPerRow_sourceBytesPerImage_sourceSize_toTexture_destinationSlice_destinationLevel_destinationOrigin_: *void = ---;
    copyFromBuffer_sourceOffset_sourceBytesPerRow_sourceBytesPerImage_sourceSize_toTexture_destinationSlice_destinationLevel_destinationOrigin_options_: *void = ---;
    copyFromTexture_sourceSlice_sourceLevel_sourceOrigin_sourceSize_toBuffer_destinationOffset_destinationBytesPerRow_destinationBytesPerImage_: *void = ---;
    copyFromTexture_sourceSlice_sourceLevel_sourceOrigin_sourceSize_toBuffer_destinationOffset_destinationBytesPerRow_destinationBytesPerImage_options_: *void = ---;
    generateMipmapsForTexture_: *void = ---;
    fillBuffer_range_value_: *void = ---;
    copyFromBuffer_sourceOffset_toBuffer_destinationOffset_size_: *void = ---;
    updateFence_: *void = ---;
    waitForFence_: *void = ---;
    optimizeContentsForGPUAccess_: *void = ---;
    optimizeContentsForGPUAccess_slice_level_: *void = ---;
    optimizeContentsForCPUAccess_: *void = ---;
    optimizeContentsForCPUAccess_slice_level_: *void = ---;
    resetCommandsInBuffer_withRange_: *void = ---;
    copyIndirectCommandBuffer_sourceRange_destination_destinationIndex_: *void = ---;
    optimizeIndirectCommandBuffer_withRange_: *void = ---;
    enqueue: *void = ---;
    commit: *void = ---;
    addScheduledHandler_: *void = ---;
    presentDrawable_: *void = ---;
    presentDrawable_atTime_: *void = ---;
    waitUntilScheduled: *void = ---;
    addCompletedHandler_: *void = ---;
    completedHandler: *void = ---;
    waitUntilCompleted: *void = ---;
    blitCommandEncoder: *void = ---;
    renderCommandEncoderWithDescriptor_: *void = ---;
    computeCommandEncoder: *void = ---;
    computeCommandEncoderWithDispatchType_: *void = ---;
    encodeWaitForEvent_value_: *void = ---;
    encodeSignalEvent_value_: *void = ---;
    parallelRenderCommandEncoderWithDescriptor_: *void = ---;
    commandQueue: *void = ---;
    retainedReferences: *void = ---;
    kernelStartTime: *void = ---;
    kernelEndTime: *void = ---;
    GPUStartTime: *void = ---;
    GPUEndTime: *void = ---;
    status: *void = ---;
    error: *void = ---;
    setComputePipelineState_: *void = ---;
    setBytes_length_atIndex_: *void = ---;
    setBuffer_offset_atIndex_: *void = ---;
    setBufferOffset_atIndex_: *void = ---;
    setBuffers_offsets_withRange_: *void = ---;
    setTexture_atIndex_: *void = ---;
    setTextures_withRange_: *void = ---;
    setSamplerState_atIndex_: *void = ---;
    setSamplerStates_withRange_: *void = ---;
    setSamplerState_lodMinClamp_lodMaxClamp_atIndex_: *void = ---;
    setSamplerStates_lodMinClamps_lodMaxClamps_withRange_: *void = ---;
    setThreadgroupMemoryLength_atIndex_: *void = ---;
    setStageInRegion_: *void = ---;
    setStageInRegionWithIndirectBuffer_indirectBufferOffset_: *void = ---;
    dispatchThreadgroups_threadsPerThreadgroup_: *void = ---;
    dispatchThreadgroupsWithIndirectBuffer_indirectBufferOffset_threadsPerThreadgroup_: *void = ---;
    dispatchThreads_threadsPerThreadgroup_: *void = ---;
    useResource_usage_: *void = ---;
    useResources_count_usage_: *void = ---;
    useHeap_: *void = ---;
    useHeaps_count_: *void = ---;
    memoryBarrierWithScope_: *void = ---;
    memoryBarrierWithResources_count_: *void = ---;
    dispatchType: *void = ---;
    commandBuffer: *void = ---;
    commandBufferWithUnretainedReferences: *void = ---;
    insertDebugCaptureBoundary: *void = ---;
    stencilCompareFunction: *void = ---;
    setStencilCompareFunction_: *void = ---;
    stencilFailureOperation: *void = ---;
    setStencilFailureOperation_: *void = ---;
    depthFailureOperation: *void = ---;
    setDepthFailureOperation_: *void = ---;
    depthStencilPassOperation: *void = ---;
    setDepthStencilPassOperation_: *void = ---;
    readMask: *void = ---;
    setReadMask_: *void = ---;
    writeMask: *void = ---;
    setWriteMask_: *void = ---;
    depthCompareFunction: *void = ---;
    setDepthCompareFunction_: *void = ---;
    isDepthWriteEnabled: *void = ---;
    setDepthWriteEnabled_: *void = ---;
    frontFaceStencil: *void = ---;
    setFrontFaceStencil_: *void = ---;
    backFaceStencil: *void = ---;
    setBackFaceStencil_: *void = ---;
    present: *void = ---;
    presentAtTime_: *void = ---;
    texture: *void = ---;
    setTexture_: *void = ---;
    level: *void = ---;
    setLevel_: *void = ---;
    slice: *void = ---;
    setSlice_: *void = ---;
    depthPlane: *void = ---;
    setDepthPlane_: *void = ---;
    resolveTexture: *void = ---;
    setResolveTexture_: *void = ---;
    resolveLevel: *void = ---;
    setResolveLevel_: *void = ---;
    resolveSlice: *void = ---;
    setResolveSlice_: *void = ---;
    resolveDepthPlane: *void = ---;
    setResolveDepthPlane_: *void = ---;
    loadAction: *void = ---;
    setLoadAction_: *void = ---;
    storeAction: *void = ---;
    setStoreAction_: *void = ---;
    storeActionOptions: *void = ---;
    setStoreActionOptions_: *void = ---;
    clearColor: *void = ---;
    setClearColor_: *void = ---;
    clearDepth: *void = ---;
    setClearDepth_: *void = ---;
    depthResolveFilter: *void = ---;
    setDepthResolveFilter_: *void = ---;
    clearStencil: *void = ---;
    setClearStencil_: *void = ---;
    stencilResolveFilter: *void = ---;
    setStencilResolveFilter_: *void = ---;
    objectAtIndexedSubscript_: *void = ---;
    setObject_atIndexedSubscript_: *void = ---;
    renderPassDescriptor: *void = ---;
    setSamplePositions_count_: *void = ---;
    getSamplePositions_count_: *void = ---;
    colorAttachments: *void = ---;
    depthAttachment: *void = ---;
    setDepthAttachment_: *void = ---;
    stencilAttachment: *void = ---;
    setStencilAttachment_: *void = ---;
    visibilityResultBuffer: *void = ---;
    setVisibilityResultBuffer_: *void = ---;
    renderTargetArrayLength: *void = ---;
    setRenderTargetArrayLength_: *void = ---;
    setStride_: *void = ---;
    stepFunction: *void = ---;
    setStepFunction_: *void = ---;
    stepRate: *void = ---;
    setStepRate_: *void = ---;
    format: *void = ---;
    setFormat_: *void = ---;
    setOffset_: *void = ---;
    bufferIndex: *void = ---;
    setBufferIndex_: *void = ---;
    stageInputOutputDescriptor: *void = ---;
    reset: *void = ---;
    layouts: *void = ---;
    attributes: *void = ---;
    indexType: *void = ---;
    setIndexType_: *void = ---;
    indexBufferIndex: *void = ---;
    setIndexBufferIndex_: *void = ---;
    mutability: *void = ---;
    setMutability_: *void = ---;
    arguments: *void = ---;
    computeFunction: *void = ---;
    setComputeFunction_: *void = ---;
    threadGroupSizeIsMultipleOfThreadExecutionWidth: *void = ---;
    setThreadGroupSizeIsMultipleOfThreadExecutionWidth_: *void = ---;
    maxTotalThreadsPerThreadgroup: *void = ---;
    setMaxTotalThreadsPerThreadgroup_: *void = ---;
    stageInputDescriptor: *void = ---;
    setStageInputDescriptor_: *void = ---;
    buffers: *void = ---;
    threadExecutionWidth: *void = ---;
    staticThreadgroupMemoryLength: *void = ---;
    setRenderPipelineState_: *void = ---;
    setVertexBytes_length_atIndex_: *void = ---;
    setVertexBuffer_offset_atIndex_: *void = ---;
    setVertexBufferOffset_atIndex_: *void = ---;
    setVertexBuffers_offsets_withRange_: *void = ---;
    setVertexTexture_atIndex_: *void = ---;
    setVertexTextures_withRange_: *void = ---;
    setVertexSamplerState_atIndex_: *void = ---;
    setVertexSamplerStates_withRange_: *void = ---;
    setVertexSamplerState_lodMinClamp_lodMaxClamp_atIndex_: *void = ---;
    setVertexSamplerStates_lodMinClamps_lodMaxClamps_withRange_: *void = ---;
    setViewport_: *void = ---;
    setViewports_count_: *void = ---;
    setFrontFacingWinding_: *void = ---;
    setCullMode_: *void = ---;
    setDepthClipMode_: *void = ---;
    setDepthBias_slopeScale_clamp_: *void = ---;
    setScissorRect_: *void = ---;
    setScissorRects_count_: *void = ---;
    setTriangleFillMode_: *void = ---;
    setFragmentBytes_length_atIndex_: *void = ---;
    setFragmentBuffer_offset_atIndex_: *void = ---;
    setFragmentBufferOffset_atIndex_: *void = ---;
    setFragmentBuffers_offsets_withRange_: *void = ---;
    setFragmentTexture_atIndex_: *void = ---;
    setFragmentTextures_withRange_: *void = ---;
    setFragmentSamplerState_atIndex_: *void = ---;
    setFragmentSamplerStates_withRange_: *void = ---;
    setFragmentSamplerState_lodMinClamp_lodMaxClamp_atIndex_: *void = ---;
    setFragmentSamplerStates_lodMinClamps_lodMaxClamps_withRange_: *void = ---;
    setBlendColorRed_green_blue_alpha_: *void = ---;
    setDepthStencilState_: *void = ---;
    setStencilReferenceValue_: *void = ---;
    setStencilFrontReferenceValue_backReferenceValue_: *void = ---;
    setVisibilityResultMode_offset_: *void = ---;
    setColorStoreAction_atIndex_: *void = ---;
    setDepthStoreAction_: *void = ---;
    setStencilStoreAction_: *void = ---;
    setColorStoreActionOptions_atIndex_: *void = ---;
    setDepthStoreActionOptions_: *void = ---;
    setStencilStoreActionOptions_: *void = ---;
    drawPrimitives_vertexStart_vertexCount_instanceCount_: *void = ---;
    drawPrimitives_vertexStart_vertexCount_: *void = ---;
    drawIndexedPrimitives_indexCount_indexType_indexBuffer_indexBufferOffset_instanceCount_: *void = ---;
    drawIndexedPrimitives_indexCount_indexType_indexBuffer_indexBufferOffset_: *void = ---;
    drawPrimitives_vertexStart_vertexCount_instanceCount_baseInstance_: *void = ---;
    drawIndexedPrimitives_indexCount_indexType_indexBuffer_indexBufferOffset_instanceCount_baseVertex_baseInstance_: *void = ---;
    drawPrimitives_indirectBuffer_indirectBufferOffset_: *void = ---;
    drawIndexedPrimitives_indexType_indexBuffer_indexBufferOffset_indirectBuffer_indirectBufferOffset_: *void = ---;
    textureBarrier: *void = ---;
    updateFence_afterStages_: *void = ---;
    waitForFence_beforeStages_: *void = ---;
    setTessellationFactorBuffer_offset_instanceStride_: *void = ---;
    setTessellationFactorScale_: *void = ---;
    drawPatches_patchStart_patchCount_patchIndexBuffer_patchIndexBufferOffset_instanceCount_baseInstance_: *void = ---;
    drawPatches_patchIndexBuffer_patchIndexBufferOffset_indirectBuffer_indirectBufferOffset_: *void = ---;
    drawIndexedPatches_patchStart_patchCount_patchIndexBuffer_patchIndexBufferOffset_controlPointIndexBuffer_controlPointIndexBufferOffset_instanceCount_baseInstance_: *void = ---;
    drawIndexedPatches_patchIndexBuffer_patchIndexBufferOffset_controlPointIndexBuffer_controlPointIndexBufferOffset_indirectBuffer_indirectBufferOffset_: *void = ---;
    executeCommandsInBuffer_withRange_: *void = ---;
    executeCommandsInBuffer_indirectBuffer_indirectBufferOffset_: *void = ---;
    memoryBarrierWithScope_afterStages_beforeStages_: *void = ---;
    memoryBarrierWithResources_count_afterStages_beforeStages_: *void = ---;
    setConstantValue_type_atIndex_: *void = ---;
    setConstantValues_type_withRange_: *void = ---;
    setConstantValue_type_withName_: *void = ---;
    isBlendingEnabled: *void = ---;
    setBlendingEnabled_: *void = ---;
    sourceRGBBlendFactor: *void = ---;
    setSourceRGBBlendFactor_: *void = ---;
    destinationRGBBlendFactor: *void = ---;
    setDestinationRGBBlendFactor_: *void = ---;
    rgbBlendOperation: *void = ---;
    setRgbBlendOperation_: *void = ---;
    sourceAlphaBlendFactor: *void = ---;
    setSourceAlphaBlendFactor_: *void = ---;
    destinationAlphaBlendFactor: *void = ---;
    setDestinationAlphaBlendFactor_: *void = ---;
    alphaBlendOperation: *void = ---;
    setAlphaBlendOperation_: *void = ---;
    vertexArguments: *void = ---;
    fragmentArguments: *void = ---;
    vertexFunction: *void = ---;
    setVertexFunction_: *void = ---;
    fragmentFunction: *void = ---;
    setFragmentFunction_: *void = ---;
    vertexDescriptor: *void = ---;
    setVertexDescriptor_: *void = ---;
    rasterSampleCount: *void = ---;
    setRasterSampleCount_: *void = ---;
    isAlphaToCoverageEnabled: *void = ---;
    setAlphaToCoverageEnabled_: *void = ---;
    isAlphaToOneEnabled: *void = ---;
    setAlphaToOneEnabled_: *void = ---;
    isRasterizationEnabled: *void = ---;
    setRasterizationEnabled_: *void = ---;
    depthAttachmentPixelFormat: *void = ---;
    setDepthAttachmentPixelFormat_: *void = ---;
    stencilAttachmentPixelFormat: *void = ---;
    setStencilAttachmentPixelFormat_: *void = ---;
    inputPrimitiveTopology: *void = ---;
    setInputPrimitiveTopology_: *void = ---;
    tessellationPartitionMode: *void = ---;
    setTessellationPartitionMode_: *void = ---;
    maxTessellationFactor: *void = ---;
    setMaxTessellationFactor_: *void = ---;
    isTessellationFactorScaleEnabled: *void = ---;
    setTessellationFactorScaleEnabled_: *void = ---;
    tessellationFactorFormat: *void = ---;
    setTessellationFactorFormat_: *void = ---;
    tessellationControlPointIndexType: *void = ---;
    setTessellationControlPointIndexType_: *void = ---;
    tessellationFactorStepFunction: *void = ---;
    setTessellationFactorStepFunction_: *void = ---;
    tessellationOutputWindingOrder: *void = ---;
    setTessellationOutputWindingOrder_: *void = ---;
    vertexBuffers: *void = ---;
    fragmentBuffers: *void = ---;
    supportIndirectCommandBuffers: *void = ---;
    setSupportIndirectCommandBuffers_: *void = ---;
    renderCommandEncoder: *void = ---;
    minFilter: *void = ---;
    setMinFilter_: *void = ---;
    magFilter: *void = ---;
    setMagFilter_: *void = ---;
    mipFilter: *void = ---;
    setMipFilter_: *void = ---;
    maxAnisotropy: *void = ---;
    setMaxAnisotropy_: *void = ---;
    sAddressMode: *void = ---;
    setSAddressMode_: *void = ---;
    tAddressMode: *void = ---;
    setTAddressMode_: *void = ---;
    rAddressMode: *void = ---;
    setRAddressMode_: *void = ---;
    borderColor: *void = ---;
    setBorderColor_: *void = ---;
    normalizedCoordinates: *void = ---;
    setNormalizedCoordinates_: *void = ---;
    lodMinClamp: *void = ---;
    setLodMinClamp_: *void = ---;
    lodMaxClamp: *void = ---;
    setLodMaxClamp_: *void = ---;
    lodAverage: *void = ---;
    setLodAverage_: *void = ---;
    compareFunction: *void = ---;
    setCompareFunction_: *void = ---;
    supportArgumentBuffers: *void = ---;
    setSupportArgumentBuffers_: *void = ---;
    size: *void = ---;
    setSize_: *void = ---;
    maxAvailableSizeWithAlignment_: *void = ---;
    usedSize: *void = ---;
    setArgumentBuffer_offset_: *void = ---;
    setArgumentBuffer_startOffset_arrayElement_: *void = ---;
    constantDataAtIndex_: *void = ---;
    setRenderPipelineState_atIndex_: *void = ---;
    setRenderPipelineStates_withRange_: *void = ---;
    setIndirectCommandBuffer_atIndex_: *void = ---;
    setIndirectCommandBuffers_withRange_: *void = ---;
    newArgumentEncoderForBufferAtIndex_: *void = ---;
    encodedLength: *void = ---;
    sharedCaptureManager: *void = ---;
    init: *void = ---;
    newCaptureScopeWithDevice_: *void = ---;
    newCaptureScopeWithCommandQueue_: *void = ---;
    startCaptureWithDevice_: *void = ---;
    startCaptureWithCommandQueue_: *void = ---;
    startCaptureWithScope_: *void = ---;
    stopCapture: *void = ---;
    defaultCaptureScope: *void = ---;
    setDefaultCaptureScope_: *void = ---;
    isCapturing: *void = ---;
    beginScope: *void = ---;
    endScope: *void = ---;
    drawPatches_patchStart_patchCount_patchIndexBuffer_patchIndexBufferOffset_instanceCount_baseInstance_tessellationFactorBuffer_tessellationFactorBufferOffset_tessellationFactorBufferInstanceStride_: *void = ---;
    drawIndexedPatches_patchStart_patchCount_patchIndexBuffer_patchIndexBufferOffset_controlPointIndexBuffer_controlPointIndexBufferOffset_instanceCount_baseInstance_tessellationFactorBuffer_tessellationFactorBufferOffset_tessellationFactorBufferInstanceStride_: *void = ---;
    commandTypes: *void = ---;
    setCommandTypes_: *void = ---;
    inheritPipelineState: *void = ---;
    setInheritPipelineState_: *void = ---;
    inheritBuffers: *void = ---;
    setInheritBuffers_: *void = ---;
    maxVertexBufferBindCount: *void = ---;
    setMaxVertexBufferBindCount_: *void = ---;
    maxFragmentBufferBindCount: *void = ---;
    setMaxFragmentBufferBindCount_: *void = ---;
    resetWithRange_: *void = ---;
    indirectRenderCommandAtIndex_: *void = ---;
    initWithDispatchQueue_: *void = ---;
    dispatchQueue: *void = ---;
    notifyListener_atValue_block_: *void = ---;
    newSharedEventHandle: *void = ---;
    signaledValue: *void = ---;
    setSignaledValue_: *void = ---;

    supportsRaytracing: *void = ---;
}

__selectors: _Generated_Selectors;
