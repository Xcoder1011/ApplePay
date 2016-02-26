//
//  ViewController.m
//  ApplePayDemo
//
//  Created by wushangkun on 16/2/22.
//  Copyright © 2016年 J1. All rights reserved.
//

#import "ViewController.h"
#import <PassKit/PassKit.h>
#import <AddressBook/AddressBook.h>

@interface ViewController () <PKPaymentAuthorizationViewControllerDelegate>

@property (strong, nonatomic) UILabel *infoLabel;

@property (strong, nonatomic) PKPaymentButton *payButton;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //商品展示
    _infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(40, 60, self.view.frame.size.width-20, 100)];
    _infoLabel.text = @"购物车清单: \n\n总价: 0.01元";
    _infoLabel.numberOfLines = 0;
    [self.view addSubview:_infoLabel];
    
    //PKPaymentButton
    _payButton = [[PKPaymentButton alloc] initWithPaymentButtonType:PKPaymentButtonTypeBuy paymentButtonStyle:PKPaymentButtonStyleWhiteOutline];
    _payButton.frame = CGRectMake(50, CGRectGetMaxY(_infoLabel.frame)+20, self.view.frame.size.width-100, 40);
    [_payButton addTarget:self action:@selector(payClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_payButton];
}

- (void)payClick{
    // 1. 判断手机是否支持Apple Pay
    if([PKPaymentAuthorizationViewController canMakePayments]) {
        
        NSArray *networks = @[PKPaymentNetworkChinaUnionPay, PKPaymentNetworkVisa,PKPaymentNetworkMasterCard,PKPaymentNetworkAmex];
        // 2. 判断用户是否能够使用你提供的支付网络进行支付
        BOOL canPay = [PKPaymentAuthorizationViewController canMakePaymentsUsingNetworks:networks];
        
        NSLog(@"canPay = %d",canPay);
        
        if (!canPay) {
            // 不能支付，跳转到添加银行卡界面
            [self gotoSetupPayment];
            
        }else{
            
            /**
              * 1. 创建支付请求
              * 支付请求是PKPaymentRequest类的实例，它的组成部分包括一个用来表示将要购买的项目的摘要，一个可用的配送方式列表，
              * 一个表示用户需要提供的配送信息的描述，以及一些商家和支付平台的信息。
             */
            PKPaymentRequest *request = [[PKPaymentRequest alloc] init];
            
            /**
             *  1.1 配置国家代码,货币代码
             *  一个支付请求里的国家代码表示了这次购买发生的国家或者将要在这个国家处理这次支付
             *  所有的汇总金额应该使用同一种货币
             */
            request.countryCode = @"CN";   //以中国为例
            request.currencyCode = @"CNY";
            
            /**
             *  1.2 配置商家ID
             *  在支付请求里指定的商用ID必须匹配应用中指定的商用ID列表之一
             */
            request.merchantIdentifier = @"merchant.j1.hy.applepay";
            
            /**
             *  1.3 配置可支持的支付网络
             */
            request.supportedNetworks = @[PKPaymentNetworkChinaUnionPay,PKPaymentNetworkMasterCard,PKPaymentNetworkVisa,PKPaymentNetworkAmex];
            
            /**
             *  1.4 配置商户的处理方式
             *  支付方式 : 通过在supportedNetworks属性中填入数组来指定你支持的支付网络。
             *            通过指定merchantCapabilities属性来指定你支持的支付处理标准，
             *            3DS支付方式是必须支持的，EMV方式是可选的
             *  PKMerchantCapabilityCredit: 支持信用卡
             *  PKMerchantCapabilityDebit: 支持借记卡
             */
            request.merchantCapabilities = PKMerchantCapabilityCredit | PKMerchantCapabilityDebit | PKMerchantCapability3DS;
            
            /**
             *  1.5 配置账单信息和配送地址信息 显示哪些项 (可不填)
             *  如果已经有了用户的账单和配送信息，可以直接在支付请求中使用它们
             *  尽管Apple Pay默认使用了这些信息，用户仍然可以在授权支付的过程中修改这些信息
             */
            request.requiredBillingAddressFields = PKAddressFieldEmail ;
            request.requiredShippingAddressFields = PKAddressFieldPostalAddress | PKAddressFieldEmail;
            
            /**
             *  1.6 配置快递方式 显示哪些项 (可不填)
            *   对于每一种可用的配送方式创建一个PKShippingMethod实例
             */
            NSDecimalNumber *price1 = [NSDecimalNumber decimalNumberWithString:@"20.0"];
            PKShippingMethod *method1 = [PKShippingMethod summaryItemWithLabel:@"顺丰快递" amount:price1 type:PKPaymentSummaryItemTypeFinal];
            method1.detail = @"速度最快";
            method1.identifier = @"shunfeng";
            
            NSDecimalNumber *price2 = [NSDecimalNumber decimalNumberWithString:@"20.0"];
            PKShippingMethod *method2 = [PKShippingMethod summaryItemWithLabel:@"EMS" amount:price2 type:PKPaymentSummaryItemTypeFinal];
            method2.detail = @"下单后第二天发货";
            method2.identifier = @"EMS";
            
            request.shippingMethods = @[method1,method2];
            request.shippingType = PKShippingTypeStorePickup;
            
            /**
             *  1.7 存储额外信息
             *  使用applicationData属性来存储一些在你的应用中关于这次支付请求的唯一标识信息，比如一个购物车的标识符。
             *  在用户授权支付之后，这个属性的哈希值会出现在这次支付的token中
             */
            request.applicationData = [@"购物车ID:12345678" dataUsingEncoding:NSUTF8StringEncoding];
            

            /**
             *  2. 创建支付项目的列表
             */
            
            // item1:东阿阿胶 ¥10.0
            NSDecimalNumber *item1Price = [NSDecimalNumber decimalNumberWithString:@"10.0"];
            PKPaymentSummaryItem *item1 = [PKPaymentSummaryItem summaryItemWithLabel:@"东阿阿胶" amount:item1Price];
            
            // item2:三九感冒灵 ¥2.01
            // 这里使用NSDecimalNumber类来存储摘要项目的数额，它是一个以10为底数的数值
            // 表示201 * 10 ^ (-2)  = 2.01元
            NSDecimalNumber *item2Price = [NSDecimalNumber decimalNumberWithMantissa:201 exponent:-2 isNegative:NO];
            PKPaymentSummaryItem *item2 = [PKPaymentSummaryItem summaryItemWithLabel:@"三九感冒灵" amount:item2Price];
            
            // discount:优惠券抵扣
            NSDecimalNumber *discountPrice = [NSDecimalNumber decimalNumberWithString:@"-12"];
            PKPaymentSummaryItem *discount = [PKPaymentSummaryItem summaryItemWithLabel:@"优惠券抵扣" amount:discountPrice];
            
            // total: 总金额
            // 在这个摘要项目列表中的最后一个是总计金额
            // 总计的显示方法和其它的摘要项目不同：应该使用你公司的名称做为其标签，使用所有其它项目的金额总和做为金额
            NSDecimalNumber *totalPrice = [NSDecimalNumber zero];
            totalPrice = [totalPrice decimalNumberByAdding:item1Price];
            totalPrice = [totalPrice decimalNumberByAdding:item2Price];
            totalPrice = [totalPrice decimalNumberByAdding:discountPrice];
            PKPaymentSummaryItem *total = [PKPaymentSummaryItem summaryItemWithLabel:@"健一网" amount:totalPrice];
            
            // 你可以使用PKPaymentSummaryItem来创建物品并显示，这个对象描述了一个物品和它的价格，数组最后的对象必须是总价格
            NSArray *summaryItems = @[item1, item2, discount, total];
            request.paymentSummaryItems = summaryItems;
            
            
            /**
             *  3. 展示支付授权界面
             */
            PKPaymentAuthorizationViewController *payMentVc = [[PKPaymentAuthorizationViewController alloc] initWithPaymentRequest:request];
            payMentVc.delegate = self;
            
            if (!payMentVc) {
                NSLog(@"支付授权出了问题");
                return;
            }
            [self presentViewController:payMentVc animated:YES completion:nil];
        }
        
    }else{
        NSLog(@"该设备不支持Apple pay");
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:@"该设备不支持Apple pay" preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            [alert dismissViewControllerAnimated:YES completion:nil];
        }]];
        [self presentViewController:alert animated:YES completion:nil];
        
    }
}

// MARK: 跳转到添加银行卡界面
- (void)gotoSetupPayment
{
    [[PKPassLibrary new] openPaymentSetup];
}


/**
 *  检查支付确定付款请求是否被授权
 *
 *  @param controller 授权控制器
 *  @param payment    支付请求的结果
 *  @param completion 回调代码块
 */
-(void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller didAuthorizePayment:(PKPayment *)payment completion:(void (^)(PKPaymentAuthorizationStatus))completion{
    
    // 当用户最终授权了一个支付请求，框架会通过与苹果服务器和嵌入在设备中的一个安全模块进行通信，生成一个支付token
    // 这个token和其它一些你需要用来处理这次购买的信息--例如配送地址和购物车标识--发送给你的服务器
    NSLog(@"payment was authorized:%@",payment);
    
    // 需要连接服务器并上传支付令牌和其他信息，以完成整个支付流程
    NSLog(@"didAuthorizePayment.token = %@",payment.token);

    BOOL asycSuccessful = FALSE;
    if (asycSuccessful) {
        completion(PKPaymentAuthorizationStatusSuccess);
        NSLog(@"支付成功");
    }else{
        completion(PKPaymentAuthorizationStatusFailure);
        NSLog(@"支付失败");
    }
//    NSError *error;
//    ABMultiValueRef addressMultiValue = ABRecordCopyValue(payment.billingAddress, kABPersonAddressProperty);
//    NSDictionary *addressDictionary = (__bridge_transfer NSDictionary *) ABMultiValueCopyValueAtIndex(addressMultiValue, 0);
//    NSData *json = [NSJSONSerialization dataWithJSONObject:addressDictionary options:NSJSONWritingPrettyPrinted error: &error];
//    NSLog(@"json = %@",json);
//    // ... Send payment token, shipping and billing address, and order information to your server ...
//    PKPaymentAuthorizationStatus status;  // From your server
//    completion(status);
}


/**
 *  当用户授权成功, 或者取消授权时调用
 */
- (void)paymentAuthorizationViewControllerDidFinish:(PKPaymentAuthorizationViewController *)controller{
    [controller dismissViewControllerAnimated:TRUE completion:nil];
    //它不包含completion block，所以它可以在任何时候被调用。
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
