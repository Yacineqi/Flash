import requests
from web3 import Web3

# إعداد مزود للاتصال بشبكة بينانس (BSC) باستخدام مفتاح API الخاص بك
bsc_api_url = 'https://bsc-dataseed.binance.org/'  # تعديل إلى مزود BSC
web3 = Web3(Web3.HTTPProvider(bsc_api_url))

# التحقق من الاتصال بالشبكة
if not web3.isConnected():
    print("فشل الاتصال بشبكة بينانس")
else:
    print("تم الاتصال بنجاح بشبكة بينانس")

# عناوين عقود المنصات المستهدفة (عقود فعلية)
platforms = {
    'uniswap': "0x7A250d5630B4cF539739dF2C5dAcb4c659F2488D",  # Uniswap V3 Router
    'aaveV2': "0x3f5B2C82950D23af019509f979F2Da8D4062A522",   # Aave V2 Pool
    'aaveV3': "0x7C1A8D12bB5C74B587c7AA823F84a9C64AE716A1",  # Aave V3 Pool
    'compound': "0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643", # Compound
    'radiantV2': "0x1234567890abcdef1234567890abcdef12345678", # عنوان عقود Radiant V2 (استبدل بعنوان حقيقي)
    'spark': "0xabcdefabcdefabcdefabcdefabcdefabcdefabcd",  # عنوان عقود Spark (استبدل بعنوان حقيقي)
    'paraswapV5': "0xabcdefabcdefabcdefabcdefabcdefabcdefabcd", # عنوان عقود Paraswap V5 (استبدل بعنوان حقيقي)
}

# عناوين توكنات العملات التي تريد مراقبتها مقابل USDT
tokenAddresses = [
    '0xB0C600150D8C956fA92B98DB69A7D72FDFB0A7E6', # DOT (Polkadot)
    '0xA0b86991c6218b36c1d19d4a2e9eb0ce3606eb48', # USDC (عملة مستقرة ولكن أضفتها للمقارنة)
    '0x6B175474E89094C44Da98b954EedeAC495271d0F', # DAI
    '0xC02aaA39b223FE8D0A0eA0c4F8cB5c5c6B94C72', # WETH (إيثيريوم مغلف)
    '0x514910771AF9Ca656af840dff83E8264EcF986CA', # LINK (ChainLink)
    '0xD533a949740bb3306d119CC777fa900bA034cd52', # CRV (Curve)
    '0x111111111117dC0aa78b770fA6A738034120C302', # 1INCH (1inch)
    '0xC011A72400E58ecD99Ee497CF89E3775d4bd732F', # SNX (Synthetix)
    '0xA0b86991c6218b36c1d19d4a2e9eb0ce3606eb48', # USDC (عملة مستقرة ولكن أضفتها للمقارنة)
    '0xB73134C9496B1D2B53C0B2BBF7B4FEC292D9E39B', #  توكن غير مستقر (استبدل بعنوان حقيقي)
]

# بيانات بوت Telegram
TELEGRAM_API_TOKEN = '7371692002:AAGnvQSA94xyu2B2dppKjhrrG03NRyjmu'
TELEGRAM_CHAT_ID = '749342823'

# دالة لإرسال رسالة إلى Telegram
def sendTelegramMessage(message):
    url = f'https://api.telegram.org/bot{TELEGRAM_API_TOKEN}/sendMessage'
    payload = {
        'chat_id': TELEGRAM_CHAT_ID,
        'text': message
    }
    try:
        response = requests.post(url, data=payload)
        if response.status_code != 200:
            print(f"فشل إرسال الرسالة: {response.text}")
        else:
            print("تم إرسال الرسالة بنجاح")
    except Exception as e:
        print(f"حدث خطأ أثناء إرسال الرسالة: {str(e)}")

# دالة لجلب السعر من Uniswap باستخدام Quoter contract
def getPriceFromUniswap(tokenAddress, usdtAddress):
    quoter_address = '0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6'  # Uniswap V3 Quoter contract
    quoter_contract = web3.eth.contract(address=quoter_address, abi=[{
        "inputs": [
            {"internalType": "address","name": "tokenIn","type": "address"},
            {"internalType": "address","name": "tokenOut","type": "address"},
            {"internalType": "uint24","name": "fee","type": "uint24"},
            {"internalType": "uint256","name": "amountIn","type": "uint256"},
            {"internalType": "uint160","name": "sqrtPriceLimitX96","type": "uint160"}
        ],
        "name": "quoteExactInputSingle",
        "outputs": [{"internalType": "uint256","name": "amountOut","type": "uint256"}],
        "stateMutability": "view","type": "function"
    }])

    amount_in = web3.toWei(1, 'ether')  # سعر رمزي
    fee_tier = 3000  # Uniswap V3 fee tier (0.3%)
    sqrt_price_limit = 0

    price = quoter_contract.functions.quoteExactInputSingle(
        tokenAddress, usdtAddress, fee_tier, amount_in, sqrt_price_limit
    ).call()

    return web3.fromWei(price, 'ether')

# دالة لجلب السعر من Aave
def getPriceFromAave(tokenAddress, platform):
    if platform == 'aaveV2':
aave_contract_address = platforms['aaveV2']
        aave_abi = [{"inputs":[],"name":"getReserveData","outputs":[{"internalType":"uint256","name":"priceInUsd","type":"uint256"}],"stateMutability":"view","type":"function"}]
    elif platform == 'aaveV3':
        aave_contract_address = platforms['aaveV3']
        aave_abi = [{"inputs":[],"name":"getReserveData","outputs":[{"internalType":"uint256","name":"priceInUsd","type":"uint256"}],"stateMutability":"view","type":"function"}]
    
    contract = web3.eth.contract(address=aave_contract_address, abi=aave_abi)
    price_data = contract.functions.getReserveData(tokenAddress).call()
    
    return web3.fromWei(price_data[0], 'ether')  # Assuming price in USD

# دالة لجلب السعر من Compound
def getPriceFromCompound(tokenAddress):
    compound_contract_address = platforms['compound']
    compound_abi = [{
        "inputs": [],
        "name": "getUnderlyingPrice",
        "outputs": [{"internalType": "uint256","name":"","type":"uint256"}],
        "stateMutability": "view",
        "type": "function"
    }]
    
    contract = web3.eth.contract(address=compound_contract_address, abi=compound_abi)
    price_data = contract.functions.getUnderlyingPrice(tokenAddress).call()
    
    return web3.fromWei(price_data, 'ether')

# دالة للمقارنة بين الأسعار
def comparePrices(tokenAddress, usdtAddress):
    prices = {}
    prices['uniswap'] = getPriceFromUniswap(tokenAddress, usdtAddress)
    prices['aaveV2'] = getPriceFromAave(tokenAddress, 'aaveV2')
    prices['aaveV3'] = getPriceFromAave(tokenAddress, 'aaveV3')
    prices['compound'] = getPriceFromCompound(tokenAddress)
    # يمكنك إضافة دوال لجلب السعر من Radiant V2 و Spark و Paraswap V5 هنا

    maxPrice = max(prices.values())
    minPrice = min(prices.values())
    priceDifference = maxPrice - minPrice

    # التحقق من فرق السعر
    if priceDifference >= 0.005:  # فرق سعر 0.5% أو أكثر
        maxPlatform = max(prices, key=prices.get)
        minPlatform = min(prices, key=prices.get)

        message = f"أكبر فرق سعر بين المنصات:\n{maxPlatform}: {maxPrice} - {minPlatform}: {minPrice}\nفرق السعر: {priceDifference}\nالرمز: {tokenAddress}"
        print(message)
        sendTelegramMessage(message)

# استدعاء
