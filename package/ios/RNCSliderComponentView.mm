#ifdef RCT_NEW_ARCH_ENABLED

#import "RNCSliderComponentView.h"

#import <React/RCTConversions.h>

#import <react/renderer/components/RNCSlider/ComponentDescriptors.h>
#import <react/renderer/components/RNCSlider/EventEmitters.h>
#import <react/renderer/components/RNCSlider/Props.h>
#import <react/renderer/components/RNCSlider/RCTComponentViewHelpers.h>

#import "RCTFabricComponentsPlugins.h"
#import "RNCSlider.h"


using namespace facebook::react;

@interface RNCSliderComponentView () <RCTRNCSliderViewProtocol>

@end


@implementation RNCSliderComponentView
{
    RNCSlider *slider;
    BOOL _isSliding;
}

+ (ComponentDescriptorProvider)componentDescriptorProvider
{
    return concreteComponentDescriptorProvider<RNCSliderComponentDescriptor>();
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        static const auto defaultProps = std::make_shared<const RNCSliderProps>();
        _props = defaultProps;
        slider = [[RNCSlider alloc] initWithFrame:self.bounds];
        [slider addTarget:self action:@selector(sliderValueChanged:)
         forControlEvents:UIControlEventValueChanged];
        [slider addTarget:self action:@selector(sliderTouchStart:)
         forControlEvents:UIControlEventTouchDown];
        [slider addTarget:self action:@selector(sliderTouchEnd:)
         forControlEvents:(UIControlEventTouchUpInside |
                           UIControlEventTouchUpOutside |
                           UIControlEventTouchCancel)];
        
        UITapGestureRecognizer *tapGesturer;
        tapGesturer = [[UITapGestureRecognizer alloc] initWithTarget: self action:@selector(tapHandler:)];
        [tapGesturer setNumberOfTapsRequired: 1];
        [slider addGestureRecognizer:tapGesturer];
        
        slider.value = (float)defaultProps->value;
        self.contentView = slider;
    }
    return self;
}

- (void)tapHandler:(UITapGestureRecognizer *)gesture {
  if ([gesture.view class] != [RNCSlider class]) {
    return;
  }
  RNCSlider *slider = (RNCSlider *)gesture.view;
  slider.isSliding = _isSliding;

  // Ignore this tap if in the middle of a slide.
  if (_isSliding) {
    return;
  }

  if (!slider.tapToSeek) {
    return;
  }

  CGPoint touchPoint = [gesture locationInView:slider];
  float rangeWidth = slider.maximumValue - slider.minimumValue;
  float sliderPercent = touchPoint.x / slider.bounds.size.width;
  slider.lastValue = slider.value;
  float value = slider.minimumValue + (rangeWidth * sliderPercent);

  [slider setValue:[slider discreteValue:value] animated: YES];

    std::dynamic_pointer_cast<const RNCSliderEventEmitter>(_eventEmitter)
      ->onRNCSliderSlidingStart(RNCSliderEventEmitter::OnRNCSliderSlidingStart{.value = static_cast<Float>(value)});

  // Trigger onValueChange to address https://github.com/react-native-community/react-native-slider/issues/212
    std::dynamic_pointer_cast<const RNCSliderEventEmitter>(_eventEmitter)
      ->onRNCSliderValueChange(RNCSliderEventEmitter::OnRNCSliderValueChange{.value = static_cast<Float>(value)});

    std::dynamic_pointer_cast<const RNCSliderEventEmitter>(_eventEmitter)
      ->onRNCSliderSlidingComplete(RNCSliderEventEmitter::OnRNCSliderSlidingComplete{.value = static_cast<Float>(value)});
}

- (void)sliderValueChanged:(RNCSlider *)sender
{
    [self RNCSendSliderEvent:sender withContinuous:YES isSlidingStart:NO];
}

- (void)sliderTouchStart:(RNCSlider *)sender
{
    [self RNCSendSliderEvent:sender withContinuous:NO isSlidingStart:YES];
    sender.isSliding = YES;
    _isSliding = YES;
}

- (void)sliderTouchEnd:(RNCSlider *)sender
{
    [self RNCSendSliderEvent:sender withContinuous:NO isSlidingStart:NO];
    sender.isSliding = YES;
    _isSliding = NO;
}

- (void)RNCSendSliderEvent:(RNCSlider *)sender withContinuous:(BOOL)continuous isSlidingStart:(BOOL)isSlidingStart
{
    float value = [sender discreteValue:sender.value];
    
    if(!sender.isSliding) {
        [sender setValue:value animated:NO];
    }
    
    if (continuous) {
        if (sender.lastValue != value)  {
            std::dynamic_pointer_cast<const RNCSliderEventEmitter>(_eventEmitter)
            ->onRNCSliderValueChange(RNCSliderEventEmitter::OnRNCSliderValueChange{.value = static_cast<Float>(value)});
        }
    } else {
        if (!isSlidingStart) {
            std::dynamic_pointer_cast<const RNCSliderEventEmitter>(_eventEmitter)
            ->onRNCSliderSlidingComplete(RNCSliderEventEmitter::OnRNCSliderSlidingComplete{.value = static_cast<Float>(value)});
        }
        if (isSlidingStart) {
            std::dynamic_pointer_cast<const RNCSliderEventEmitter>(_eventEmitter)
            ->onRNCSliderSlidingStart(RNCSliderEventEmitter::OnRNCSliderSlidingStart{.value = static_cast<Float>(value)});
        }
    }
    
    sender.lastValue = value;
}

- (void)updateProps:(const Props::Shared &)props oldProps:(const Props::Shared &)oldProps
{
    const auto &oldScreenProps = *std::static_pointer_cast<const RNCSliderProps>(_props);
    const auto &newScreenProps = *std::static_pointer_cast<const RNCSliderProps>(props);
    
    if (oldScreenProps.value != newScreenProps.value) {
        slider.value = newScreenProps.value;
    }
    if (oldScreenProps.disabled != newScreenProps.disabled) {
        slider.enabled = !newScreenProps.disabled;
    }
    if (oldScreenProps.step != newScreenProps.step) {
        slider.step = newScreenProps.step;
    }
    if (oldScreenProps.inverted != newScreenProps.inverted) {
        [self setInverted:newScreenProps.inverted];
    }
    if (oldScreenProps.maximumValue != newScreenProps.maximumValue) {
        [slider setMaximumValue:newScreenProps.maximumValue];
    }
    if (oldScreenProps.tapToSeek != newScreenProps.tapToSeek) {
        slider.tapToSeek = newScreenProps.tapToSeek;
    }
    if (oldScreenProps.minimumValue != newScreenProps.minimumValue) {
        [slider setMinimumValue:newScreenProps.minimumValue];
    }
    if (oldScreenProps.thumbTintColor != newScreenProps.thumbTintColor) {
        slider.thumbTintColor = RCTUIColorFromSharedColor(newScreenProps.thumbTintColor);
    }
    if (oldScreenProps.minimumTrackTintColor != newScreenProps.minimumTrackTintColor) {
        slider.minimumTrackTintColor = RCTUIColorFromSharedColor(newScreenProps.minimumTrackTintColor);
    }
    if (oldScreenProps.maximumTrackTintColor != newScreenProps.maximumTrackTintColor) {
        slider.maximumTrackTintColor = RCTUIColorFromSharedColor(newScreenProps.maximumTrackTintColor);
    }
    if (oldScreenProps.accessibilityUnits != newScreenProps.accessibilityUnits) {
        NSString *convertedAccessibilityUnits = [NSString stringWithCString:newScreenProps.accessibilityUnits.c_str()
                                                                   encoding:[NSString defaultCStringEncoding]];
        slider.accessibilityUnits = convertedAccessibilityUnits;
    }
    if (oldScreenProps.accessibilityIncrements != newScreenProps.accessibilityIncrements) {
        id accessibilityIncrements = [NSArray new];
        for (auto str : newScreenProps.accessibilityIncrements) {
            [accessibilityIncrements addObject:[NSString stringWithUTF8String:str.c_str()]];
        }
        [slider setAccessibilityIncrements:accessibilityIncrements];
    }
    [super updateProps:props oldProps:oldProps];
}

- (void)setInverted:(BOOL)inverted
{
    if (inverted) {
        self.transform = CGAffineTransformMakeScale(-1, 1);
    } else {
        self.transform = CGAffineTransformMakeScale(1, 1);
    }
}

@end

Class<RCTComponentViewProtocol> RNCSliderCls(void)
{
    return RNCSliderComponentView.class;
}

#endif
