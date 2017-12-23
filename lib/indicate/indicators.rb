module Indicate
  class Indicators
    attr_accessor :calculator, :verbose
    
    def initialize(verbose: true)
      self.calculator   =   ::Trading::Calculations.new
      self.verbose      =   verbose
    end
    
    def verbose?
      self.verbose
    end
    
    #
    # Average True Range
    # http://www.investopedia.com/articles/trading/08/atr.asp
    # The idea is to use ATR to identify breakouts
    #
    # If the price goes higher than the previous close + ATR, a price breakout has occurred.
    # If the price goes below the previous close + ATR, a downtrend has started.
    #
    # This algorithm uses ATR as a momentum strategy, but the same signal can be used for
    # a reversion strategy, since ATR doesn't indicate the price direction (like adx below)
    #
    def atr(data, time_period: 14, multiple: 1.0)
      atrs          =   self.calculator.atr(data, time_period: time_period)
      
      if atrs&.any?
        current     =   data[:close][-1]
        previous    =   data[:close][-2]
        
        puts "[Trading::Indicators#atr(time_period: #{time_period}, multiple: #{multiple})] - current price: #{current}, previous price: #{previous}, current atr: #{atrs.last}" if verbose?
        
        atr         =   atrs.last
        atr         =   atr * multiple if !multiple.nil?
        
        uptrend     =   (current > (previous + atr))
        downtrend   =   (current < (previous + atr))
        
        if uptrend
          return 1
        elsif downtrend
          return -1
        end
      end
      
      return 0
    end
    
    #
    #          Average Directional Movement Index
    #
    #      TODO, this one needs more research for the returns
    #      http://www.investopedia.com/terms/a/adx.asp
    #
    # The ADX calculates the potential strength of a trend.
    # It fluctuates from 0 to 100, with readings below 20 indicating a weak trend and readings above 50 signaling a strong trend.
    # ADX can be used as confirmation whether the pair could possibly continue in its current trend or not.
    # ADX can also be used to determine when one should close a trade early. For instance, when ADX starts to slide below 50,
    # it indicates that the current trend is possibly losing steam.
    #
    def adx(data, time_period: 14, strong: 50, weak: 20)
      adx       =   self.calculator.adx(data, time_period: time_period)
      
      if adx > strong
        return -1 # Overbought
      elsif adx < weak
        return 1 # Oversold
      else
        return 0
      end
    end
    
    # This algorithm uses the talib Bollinger Bands function to determine entry entry
    # points for long and sell/short positions.
    #
    # When the price breaks out of the upper Bollinger band, a sell or short position
    # is opened. A long position is opened when the price dips below the lower band.
    #
    #
    # Used to measure the market’s volatility.
    # They act like mini support and resistance levels.
    # Bollinger Bounce
    #
    # A strategy that relies on the notion that price tends to always return to the middle of the Bollinger bands.
    # You buy when the price hits the lower Bollinger band.
    # You sell when the price hits the upper Bollinger band.
    # Best used in ranging markets.
    # Bollinger Squeeze
    #
    # A strategy that is used to catch breakouts early.
    # When the Bollinger bands “squeeze”, it means that the market is very quiet, and a breakout is eminent.
    # Once a breakout occurs, we enter a trade on whatever side the price makes its breakout.
    #
    def bollinger_bands(data, time_period: 10, deviations_up: 2, deviations_down: 2, ma_type: :sma)
      bands         =   self.calculator.bollinger_bands(data, time_period: time_period, deviations_up: deviations_up, deviations_down: deviations_down, ma_type: ma_type, return_all: false)
      upper         =   bands[:upper]
      lower         =   bands[:lower]
      
      current       =   data[:close].last
      
      if current <= lower
        return 1 # buy/long
      elsif current >= upper
        return -1 # sell/short
      else
        return 0
      end
    end
    
    # Moving Average Crossover Divergence (MACD) indicator as a buy/sell signal.
    # When the MACD signal less than 0, the price is trending down and it's time to sell.
    # When the MACD signal greater than 0, the price is trending up it's time to buy.
    #
    # Used to catch trends early and can also help us spot trend reversals.
    # It consists of 2 moving averages (1 fast, 1 slow) and vertical lines called a histogram,
    # which measures the distance between the 2 moving averages.
    # Contrary to what many people think, the moving average lines are NOT moving averages of the price.
    # They are moving averages of other moving averages.
    # MACD’s downfall is its lag because it uses so many moving averages.
    # One way to use MACD is to wait for the fast line to “cross over” or “cross under” the slow line and
    # enter the trade accordingly because it signals a new trend.
    #
    def macd(data, fast_period: 12, slow_period: 26, signal_period: 9)
      macd          =   self.calculator.macd(data, fast_period: fast_period, slow_period: slow_period, signal_period: signal_period, return_all: false)
      
      return ::Trading::Calculations::INVALID_DATA_ERROR if macd.nil? || macd[:raw].nil? || macd[:signal].nil?
      
      raw           =   macd[:raw]
      signal        =   macd[:signal]
      value         =   raw - signal
      
      return evaluate_macd(value)
    end
    
    # MACD indicator with controllable types and tweakable periods.
    def macd_ext(data, fast_period: 12, fast_ma: :sma, slow_period: 26, slow_ma: :sma, signal_period: 9, signal_ma: :sma)
      macd_ext      =   self.calculator.macd_ext(data, fast_period: fast_period, fast_ma: fast_ma, slow_period: slow_period, slow_ma: slow_ma, signal_period: signal_period, signal_ma: signal_ma, return_all: false)
      
      return ::Trading::Calculations::INVALID_DATA_ERROR if macd_ext.nil? || macd_ext[:raw].nil? || macd_ext[:signal].nil?
      
      raw           =   macd_ext[:raw]
      signal        =   macd_ext[:signal]
      value         =   raw - signal
      
      return evaluate_macd(value)
    end
    
    def evaluate_macd(macd)
      if macd < 0
        return -1 # sell/short
      elsif macd > 0
        return 1 # buy/long
      else
        return 0
      end
    end
    
    # Relative Strength Index indicator as a buy/sell signal.
    #
    # Similar to the stochastic in that it indicates overbought and oversold conditions.
    # When RSI is above 70, it means that the market is overbought and we should look to sell.
    # When RSI is below 30, it means that the market is oversold and we should look to buy.
    # RSI can also be used to confirm trend formations. If you think a trend is forming, wait for
    # RSI to go above or below 50 (depending on if you’re looking at an uptrend or downtrend) before you enter a trade.
    #
    def rsi(data, time_period: 14, low: 40, high: 70)
      rsi         =   self.calculator.rsi(data, time_period: time_period, return_all: true)
      
      if !rsi.nil? && rsi.any?
        current   =   rsi.pop&.round(0)&.to_i
        previous  =   rsi.pop&.round(0)&.to_i
        
        if !previous.nil? && !current.nil?
          puts "[Trading::Indicators#rsi(time_period: #{time_period}, low: #{low}, high: #{high})] - current: #{current}, previous: #{previous}" if verbose?
          
          if previous < high && current > high
            return -1 # sell/short
          elsif previous > low && current < low
            return 1 # buy/long
          end
        end
      end
      
      return 0
    end
    
    # STOCH function to determine entry and exit points.
    # When the stochastic oscillator dips below 10, the pair is determined to be oversold
    # and a long position is opened. The position is exited when the indicator rises above 90
    # because the pair is thought to be overbought.
    #
    # Used to indicate overbought and oversold conditions.
    # When the moving average lines are above 80, it means that the market is overbought and we should look to sell.
    # When the moving average lines are below 20, it means that the market is oversold and we should look to buy.
    #
    def stoch(data, fast_k_period: 13, slow_k_period: 3, slow_k_ma: :sma, slow_d_period: 3, slow_d_ma: :sma, low: 10, high: 90)
      stochs        =   self.calculator.stoch(data, fast_k_period: fast_k_period, slow_k_period: slow_k_period, slow_k_ma: slow_k_ma, slow_d_period: slow_d_period, slow_d_ma: slow_d_ma, return_all: false)
      slow_k        =   stochs[:slow_k]
      slow_d        =   stochs[:slow_d]
      
      if slow_k < low && slow_d < low
        return 1 # oversold -> buy/long
      elsif slow_k > high && slow_d > high
        return -1 # overbought -> sell/short
      else
        return 0 # hold/await
      end
    end
    
    # fast stoch
    def stoch_f(data, fast_k_period: 13, fast_d_period: 3, fast_d_ma: :sma, low: 10, high: 90)
      stochfs       =   self.calculator.stoch_f(data, fast_k_period: fast_k_period, fast_d_period: fast_d_period, fast_d_ma: fast_d_ma)
      fast_k        =   stochfs[:fast_k]
      fast_d        =   stochfs[:fast_d]
      
      if fast_k < low && fast_d < low
        return 1 # oversold -> buy/long
      elsif fast_k > high && fast_d > high
        return -1 # overbought -> sell/short
      else
        return 0 # hold/await
      end
    end
    
    # created based on calculation here
    # https://www.tradingview.com/wiki/Awesome_Oscillator_(AO)
    # AO = SMA(High+Low)/2, 5 Periods) - SMA(High+Low/2, 34 Periods)
    #
    # a momentum indicator
    # This function just watches for zero-line crossover.
    # using return_raw you can watch for saucers and peaks and will need to
    # create a strategy for those if you want to use them.
    #
    def awesome_oscillator(data, long_period: 34, short_period: 5)
      osc           =   self.calculator.awesome_oscillator(data, long_period: long_period, short_period: short_period)
      previous      =   osc[:previous]
      current       =   osc[:current]
      
      if osc[:previous] <= 0 && osc[:current] > 0
        return 100 # Bullish -> buy/long
      elsif osc[:previous] >= 0 && osc[:current] < 0
        return -100 # Bearish -> sell/short
      else
        return 0
      end
    end
    
    # Money flow index
    def mfi(data, time_period: 14, low: 10, high: 80)
      mfi           =   self.calculator.mfi(data, time_period: time_period, return_all: false)
      
      if mfi > high
        return -1 # overbought -> sell/short
      elsif mfi < low
        return 1 # oversold -> buy/long
      else
        return 0 # hold
      end
    end
    
    #
    #   On Balance Volume
    #   http://stockcharts.com/school/doku.php?id=chart_school:technical_indicators:on_balance_volume_obv
    #   signal assumption that volume precedes price on confirmation, divergence and breakouts
    #
    #   use with mfi to confirm
    #
    #   DOES NOT CURRENTLY WORK WITH RUBY TA-LIB!
    #   Issue: https://github.com/rivella50/talib-ruby/issues/15
    def obv(data)
      obvs          =   self.calculator.obv(data, return_all: true)
      current       =   obvs.pop
      prior         =   obvs.pop
      earlier       =   obvs.pop
      
      if current > prior && prior > earlier
        return 1 # upwards momentum
      elsif current < prior && prior < earlier
        return -1 # downwards momentum
      else
        return 0
      end
    end

    #
    #      Parabolic Stop And Reversal (SAR)
    #
    #  http://www.babypips.com/school/elementary/common-chart-indicators/parabolic-sar.html
    #
    # This indicator is made to spot trend reversals, hence the name Parabolic Stop And Reversal (SAR).
    # This is the easiest indicator to interpret because it only gives bullish and bearish signals.
    # When the dots are above the candles, it is a sell signal.
    # When the dots are below the candles, it is a buy signal.
    # These are best used in trending markets that consist of long rallies and downturns.
    # $acceleration=0.02, $maximum=0.02 are tradingview defaults
    #
    def parabolic_sar(data, acceleration_factor: 0.02, maximum: 0.02)
      sars          =   self.calculator.parabolic_sar(data, acceleration_factor: acceleration_factor, maximum: maximum, return_all: true)
      current       =   sars.pop
      prior         =   sars.pop
      earlier       =   sars.pop
      
      last_high     =   data[:high].last
      last_low      =   data[:low].last
      
      #
      #  if the last three SAR points are above the candle (high) then it is a sell signal
      #  if the last three SAE points are below the candle (low) then is a buy signal
      #
      if current > last_high && prior > last_high && earlier > last_high
        return -1 # sell
      elsif current < last_low && prior < last_low && earlier < last_low
        return 1 # buy
      else
        return 0
      end
    end
    
    #
    #  This is a forex version of SAR which is used with Stoch.
    #  The idea is the positioning of the sar is above 'certain' kinds of candles
    #
    def fsar(data, acceleration_factor: 0.02, maximum: 0.02)
      sars          =   self.calculator.parabolic_sar(data, acceleration_factor: acceleration_factor, maximum: maximum, return_all: true)
      current_sar   =   sars.pop
      prior_sar     =   sars.pop
      prev_sar      =   sars.pop
      
      last_high     =   data[:high].last
      last_low      =   data[:low].last
      last_open     =   data[:open].last
      last_close    =   data[:close].last
      
      prior_high    =   data[:high].last
      prior_low     =   data[:low].last
      prior_open    =   data[:open].last
      prior_close   =   data[:close].last
      
      prev_high     =   data[:high].last
      prev_low      =   data[:low].last
      prev_open     =   data[:open].last
      prev_close    =   data[:close].last
      
      below         =   current_sar < last_low
      above         =   current_sar > last_high
      red_candle    =   last_open < last_close
      green_candle  =   last_open > last_close
      
      prior_below         =   prior_sar < prior_low
      prior_above         =   prior_sar > prior_high
      prior_red_candle    =   prior_open < prior_close
      prior_green_candle  =   prior_open > prior_close
      
      prev_below          =   prev_sar < prev_low
      prev_above          =   prev_sar > prev_high
      prev_red_candle     =   prev_open < prev_close
      prev_green_candle   =   prev_open > prev_close
      
      prior_red_candle    =   prev_red_candle || prior_red_candle ? true : false
      prior_green_candle  =   prev_green_candle || prior_green_candle ? true : false
      
      if (prior_above && prior_red_candle) && (below && green_candle)
        return 1 # SAR is below a NEW green candle -> buy signal
      elsif (prior_below && prior_green_candle) && (above && red_candle)
        return -1 # SAR is above a NEW red candle -> sell signal
      else
        return 0 # -> hold/await
      end
    end
    
    #   Commodity Channel Index   
    def cci(data, time_period: 14, low: -100, high: 100)
      cci           =   self.calculator.sar(data, time_period: time_period, return_all: false)
      
      if cci > high
        return -1 # overbought -> sell/short
      elsif cci < low
        return 1 # oversold -> buy/long
      else
        return 0 # hold
      end
    end
    
    #   Chande Momentum Oscillator 
    def cmo(data, time_period: 14, low: -50, high: 50)
      cmo           =   self.calculator.cmo(data, time_period: time_period, return_all: false)
      
      if cmo > high
        return -1 # overbought -> sell/short
      elsif cmo < low
        return 1 # oversold -> buy/long
      else
        return 0 # hold
      end
    end
    
    #   Chande Momentum Oscillator 
    def aroon_osc(data, time_period: 14, low: -50, high: 50)
      aroonosc      =   self.calculator.aroon_osc(data, time_period: time_period, return_all: false)
      
      if aroonosc < low
        return -1 # overbought -> sell/short
      elsif aroonosc > high
        return 1 # oversold -> buy/long
      else
        return 0 # hold
      end
    end
    
    #
    #          Average Directional Movement Index
    #
    #      TODO, this one needs more research for the returns
    #      http://www.investopedia.com/terms/a/adx.asp
    #
    # The ADX calculates the potential strength of a trend.
    # It fluctuates from 0 to 100, with readings below 20 indicating a weak trend and readings above 50 signaling a strong trend.
    # ADX can be used as confirmation whether the pair could possibly continue in its current trend or not.
    # ADX can also be used to determine when one should close a trade early. For instance, when ADX starts to slide below 50,
    # it indicates that the current trend is possibly losing steam.
    #
    def adx(data, time_period: 14, low: 20, high: 50)
      adx      =   self.calculator.adx(data, time_period: time_period, return_all: false)
      
      if adx > high
        return -1 # overbought -> sell/short
      elsif adx < low
        return 1 # oversold -> buy/long
      else
        return 0 # hold
      end
    end
    
    #
    #  Stochastic - relative strength index
    #  above .80 is considered overbought
    #  below .20 is considered oversold
    #  uptrend when consistently above .50
    #  downtrend when consistently below .50
    #    
    #  TA-libs stoch_rsi function seems to be broken, use regular RSI method and then calculate StochRSI
    def stoch_rsi(data, time_period: 14, low: 0.2, high: 0.8)
      stochrsi     =   self.calculator.stoch_rsi(data, time_period: time_period, return_all: false)
      
      puts "Trading::Indicators#stoch_rsi - StochRSI value: #{stochrsi}. Low: #{low}. High: #{high}" if verbose?
      
      if stochrsi < low
        return 1  # oversold -> buy/long
      elsif stochrsi > high
        return -1 # overbought -> sell/short
      else
        return 0
      end
    end
    
    #
    # Price Rate of Change
    # ROC = [(Close - Close n periods ago) / (Close n periods ago)] * 100
    # Positive values that are greater than 30 are generally interpreted as indicating overbought conditions,
    # while negative values lower than negative 30 indicate oversold conditions.
    #
    def roc(data, time_period: 14, low: -30, high: 30)
      roc           =   self.calculator.roc(data, time_period: time_period, return_all: false)
      
      puts "Trading::Indicators#roc - Roc value: #{roc}. Low: #{low}. High: #{high}" if verbose?
      
      if roc < low
        return 1 # oversold -> buy/long
      elsif roc > high
        return -1 # overbought -> sell/short
      else
        return 0 # hold/await
      end
    end
    
    #
    #  Williams R%
    #  %R = (Highest High – Closing Price) / (Highest High – Lowest Low) x -100
    #  When the indicator produces readings from 0 to -20, this indicates overbought market conditions.
    #  When readings are -80 to -100, it indicates oversold market conditions.
    #
    def will_r(data, time_period: 14, low: -80, high: -20)
      will_r        =   self.calculator.will_r(data, time_period: time_period, return_all: false)
      
      puts "Trading::Indicators#will_r - WillR value: #{will_r}. Low: #{low}. High: #{high}" if verbose?
      
      if will_r <= low
        return 1 # oversold -> buy/long
      elsif will_r >= high
        return -1 # overbought -> sell/short
      else
        return 0 #hold/await
      end
    end
    
    #
    # ULTIMATE OSCILLATOR
    #
    # BP = Close - Minimum(Low or Prior Close).
    # TR = Maximum(High or Prior Close)  -  Minimum(Low or Prior Close)
    #
    # Average7 = (7-period BP Sum) / (7-period TR Sum)
    # Average14 = (14-period BP Sum) / (14-period TR Sum)
    # Average28 = (28-period BP Sum) / (28-period TR Sum)
    #
    # UO = 100 x [(4 x Average7)+(2 x Average14)+Average28]/(4+2+1)
    #
    #  levels below 30 are deemed to be oversold
    #  levels above 70 are deemed to be overbought.
    #
    def ult_osc(data, first_period: 7, second_period: 14, third_period: 28, low: 30, high: 70)
      ult_osc       =   self.calculator.ult_osc(data, first_period: first_period, second_period: second_period, third_period: third_period, return_all: false)
      
      puts "Trading::Indicators#ult_osc - Ultimate oscillator value: #{ult_osc}. Low: #{low}. High: #{high}" if verbose?
      
      if ult_osc <= low
        return 1 # oversold -> buy/long
      elsif ult_osc >= high
        return -1 # overbought -> sell/short
      else
        return 0 # hold/await
      end
    end
    
    #
    # NO TALib function
    #
    #   High-Low index
    # Record High Percent = {New Highs / (New Highs + New Lows)} x 100
    # High-Low Index = 10-day SMA of Record High Percent
    #
    # Readings consistently above 70 usually coincide with a strong uptrend.
    # Readings consistently below 30 usually coincide with a strong downtrend.
    #
    def hli(data, time_period: 28, ma_period: 10, low_indicator: 30, high_indicator: 70)
      hli             =   self.calculator.hli(data, time_period: time_period, ma_period: ma_period, return_all: false)
      
      puts "Trading::Indicators#hli - High-Low Index value: #{hli}. Low: #{low_indicator}. High: #{high_indicator}" if verbose?
      
      if hli > high_indicator
        return 1 # strong uptrend -> buy
      elsif hli < low_indicator
        return -1 # strong downtrend -> sell
      else
        return 0
      end
    end
    
    #
    # NO TALib specific function
    #
    # Elder ray - Bull/Bear power
    # Elder uses a 13-day exponential moving average (EMA) to indicate the consensus market value.
    # Bull Power is calculated by subtracting the 13-day EMA from the day’s high.
    # Bear Power is derived by subtracting the 13-day EMA from the day’s low.
    #
    def er(data, macd_fast_period: 12, macd_slow_period: 26, macd_signal_period: 9, ema_period: 13)
      values        =   self.calculator.er(data, macd_fast_period: macd_fast_period, macd_slow_period: macd_slow_period, macd_signal_period: macd_signal_period, ema_period: ema_period)

      puts "Trading::Indicators#er - Ema current: #{values[:ema]}. Bull current: #{values[:bull]}. Bear current: #{values[:bear]}. Macd: #{values[:macd]}. Current high: #{values[:high]}. Current low: #{values[:low]}" if verbose?
      
      if values[:bull] > 0 && values[:high] > values[:macd]
        return 1 # buy
      elsif values[:bear] < 0 && values[:low] < values[:macd]
        return -1 # sell
      else
        return 0
      end
    end
    
    #
    #  NO TALib specific funciton
    #  Market Meanness Index - tendency to revert to the mean
    #  currently moving in our out of a trend?
    #  prevent loss by false trend signals
    #
    #  if mmi > 75 then not trending
    #  if mmi < 75 then trending
    #
    def mmi(data, indicator: 75)
      mmi         =   self.calculator.mmi(data)
      
      puts "Trading::Indicators#mmi - Mmi: #{mmi}, indicator: #{indicator}" if verbose?
      
      if mmi < indicator
        return 1 # buy
      elsif mmi > indicator
        return -1 # sell
      else
        return 0
      end
    end
    
    #
    #
    #      Hilbert Transform - Sinewave
    #      negative numbers = uptrend
    #      positive numbers = downtrend
    #
    #      If leadSine crosses over DCSine then buy
    #      If leadSine crosses under DCSine then sell
    #
    #      This is correct to the best of my knowledge, the TAlib funcitons are a little
    #      different than the Mesa one I think.
    #
    #      If this is incorrect, please let me know.
    #
    def ht_sine(data, evaluate: :signal)
      values              =   self.calculator.ht_sine(data, return_all: true)
      sines               =   values[:sine]
      lead_sines          =   values[:lead_sine]
      
      current_sine        =   sines.pop
      prev_sine           =   sines.pop
      
      current_lead_sine   =   lead_sines.pop
      prev_lead_sine      =   lead_sines.pop
      
      puts "Trading::Indicators#ht_sine - Current sine: #{current_sine}. Previous sine: #{prev_sine}. Current lead sine: #{current_lead_sine}. Previous lead sine: #{prev_lead_sine}" if verbose?
      
      if evaluate.to_sym.eql?(:trend)
        if current_sine < 0 && prev_sine < 0 && current_lead_sine < 0 && prev_lead_sine < 0
          return 1 # uptrend
        elsif current_sine > 0 && prev_sine > 0 && current_lead_sine > 0 && prev_lead_sine > 0
          return -1 # downtrend
        else
          return 0 # no trend
        end
      
      elsif evaluate.to_sym.eql?(:signal)
        if current_lead_sine > current_sine && prev_lead_sine <= prev_sine
          return 1 # buy
        elsif current_lead_sine < current_sine && prev_lead_sine >= prev_sine
          return -1 # buy
        else
          return 0 # hold/await
        end
      end
    end
    
    #
    #      Hilbert Transform - Instantaneous Trendline
    #      WMA(4)
    #      trader_ht_trendline
    #
    #      if WMA(4) < htl for five periods then in downtrend (sell in trend mode)
    #      if WMA(4) > htl for five periods then in uptrend   (buy in trend mode)
    #
    #      // if price is 1.5% more than trendline, then  declare a trend
    #      (WMA(4)-trendline)/trendline >= 0.15 then trend = 1
    #
    #
    def ht_trend_line(data, wma_period: 4, indicator: 0.15)
      #return {uptrend: uptrend, downtrend: downtrend, declared: declared}
      values        =   self.calculator.ht_trend_line(data, wma_period: wma_period)
      
      puts "Trading::Indicators#ht_trend_line - Uptrend: #{values[:uptrend]}. Downtrend: #{values[:downtrend]}. Declared: #{values[:declared]}. Indicator: #{indicator}" if verbose?
      
      if values[:uptrend] || values[:declared] >= indicator
        return 1 # buy
      elsif values[:downtrend] || values[:declared] <= indicator
        return -1 # sell
      else
        return 0
      end
    end
    
    #
    #
    #      Hilbert Transform - Trend vs Cycle Mode
    #      if > 1 then in trend mode ???
    #
    def ht_trend_mode(data, indicator: 1, evaluate: :signal)
      trends      =   self.calculator.ht_trend_mode(data, return_all: true)
      htm         =   trends.last
      
      puts "Trading::Indicators#ht_trend_mode - trend mode: #{htm}" if verbose?
      
      if evaluate.to_sym.eql?(:trend)
        periods   =   0
        
        0.upto(trends.size-1).each do |index|
          prev    =   trends.pop
          
          if prev == htm
            periods += 1
          else
            break
          end
        end
        
        return periods
        
      elsif evaluate.to_sym.eql?(:signal)
        if htm == indicator
          return 1 # trending
        else
          return 0 # cycling
        end
      end
    end
    
    #
    # Ema Crossover Indicator
    # 
    # Looks for crossovers (upwards and downwards) between a short EMA and a longer EMA
    # If the shorter EMA crosses the longer EMA in an upward direction -> we buy
    # If the shorter EMA crosses the longer EMA in a downward direction -> we sell
    # Otherwise we just hold/await
    # 
    def ema_crossover(data, short_period: 5, long_period: 20, compare_with_previous: true)
      ema_short           =   self.calculator.ema(data[:close], time_period: short_period, return_all: true)
      ema_long            =   self.calculator.ema(data[:close], time_period: long_period, return_all: true)
      
      if ema_short&.any? && ema_long&.any?
        current_short     =   ema_short.pop
        previous_short    =   ema_short.pop
      
        current_long      =   ema_long.pop
        previous_long     =   ema_long.pop
      
        cross_upwards     =   current_short > current_long
        cross_downwards   =   current_short < current_long
      
        puts "[Trading::Indicators#ema_crossover(short_period: #{short_period}, long_period: #{long_period})] - current short: #{current_short}, previous short: #{previous_short}, current long: #{current_long}, previous long: #{previous_long}" if verbose?
      
        if compare_with_previous
          if previous_short < current_long && cross_upwards
            return 1 # buy/long
          elsif previous_short > current_long && cross_downwards
            return -1 # sell/short
          else
            return 0
          end
        else
          if cross_upwards
            return 1 # buy/long
          elsif cross_downwards
            return -1 # sell/short
          else
            return 0
          end
        end
      else
        return nil
      end
    end
    
    #
    # Ema Triple Crossover Indicator
    # 
    # Looks for crossovers (upwards and downwards) between a short EMA, a medium EMA and a long EMA
    # If the shorter EMA crosses the longer EMA in an upward direction -> we buy
    # If the shorter EMA crosses the longer EMA in a downward direction -> we sell
    # Otherwise we just hold/await
    # 
    def ema_triple_crossover(data, short_period: 5, medium_period: 9, long_period: 20, compare_with_previous: true)
      ema_short           =   self.calculator.ema(data[:close], time_period: short_period, return_all: true)
      ema_medium          =   self.calculator.ema(data[:close], time_period: medium_period, return_all: true)
      ema_long            =   self.calculator.ema(data[:close], time_period: long_period, return_all: true)
      
      if ema_short&.any? && ema_medium&.any? && ema_long&.any?
        current_short     =   ema_short.pop
        previous_short    =   ema_short.pop
        
        current_medium    =   ema_medium.pop
        previous_medium   =   ema_medium.pop
        
        current_long      =   ema_long.pop
        previous_long     =   ema_long.pop
      
        cross_upwards     =   current_short > current_long
        cross_downwards   =   current_short < current_long
      
        puts "[Trading::Indicators#ema_triple_crossover(short_period: #{short_period}, medium_period: #{medium_period}, long_period: #{long_period})] - current short: #{current_short}, previous short: #{previous_short}, current medium: #{current_medium}, previous medium: #{previous_medium}, current long: #{current_long}, previous long: #{previous_long}" if verbose?
        
        if compare_with_previous
          if previous_short < current_medium && current_short > current_medium && previous_medium < current_long && current_medium > current_long
            return 1 # buy/long
          elsif previous_short > current_medium && current_short < current_medium && previous_medium > current_long && current_medium < current_long
            return -1 # sell/short
          else
            return 0
          end
        else
          if current_short > current_medium && current_medium > current_long
            return 1 # buy/long
          elsif current_short < current_medium && current_medium < current_long
            return -1 # sell/short
          else
            return 0
          end
        end
      else
        return nil
      end
    end
    
  end
end
