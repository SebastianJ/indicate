include Indicator
include Indicator::AutoGen

module Indicate
  class Calculations
    MA_MAPPINGS = {
      sma:   0,  # Simple moving average
      ema:   1,  # Exponential moving average
      wma:   2,  # weighted moving average
      dema:  3,  # Double Exponential Moving Average
      tema:  4,  # Triple Exponential Moving Average
      trima: 5,  # Triangular Moving Average
      kama:  6,  # Kaufman's Adaptive Moving Average
      mama:  7,  # The Mother of Adaptive Moving Average
      t3:    8   # Triple Exponential Average
    }
    
    INVALID_DATA_ERROR = nil
    
    def ma_constant(symbol)
      MA_MAPPINGS[symbol.to_sym]
    end
    
    def valid_parameters(data: [], keys: [], required_size: nil)
      valid     =   !data.nil? && !data.empty?
      
      keys.each do |key|
        valid   =   !data[key].nil? && !data[key].empty?
        valid   =   required_size.nil? ? valid : data[key].size >= required_size
      end if valid
      
      return valid
    end
    
    include ::Indicate::MovingAverages
    
    #
    # Average True Range
    # http://www.investopedia.com/articles/trading/08/atr.asp
    # The idea is to use ATR to identify breakouts
    # If the price goes higher than the previous close + ATR, a price breakout has occurred.
    #
    # The position is closed when the price goes 1 ATR below the previous close.
    #
    # This algorithm uses ATR as a momentum strategy, but the same signal can be used for
    # a reversion strategy, since ATR doesn't indicate the price direction (like adx below)
    #
    def atr(data, time_period: 14)
      return INVALID_DATA_ERROR if !valid_parameters(data: data, keys: [:high, :low, :close], required_size: time_period)
      return Atr.new(time_period: time_period).run(data[:high], data[:low], data[:close])
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
    def adx(data, time_period: 14, return_all: false)
      # ADX seems to require at least a dataset of 2x the time period
      return INVALID_DATA_ERROR if !valid_parameters(data: data, keys: [:high, :low, :close], required_size: time_period * 2)

      values      =   Adx.new(time_period: time_period).run(data[:high], data[:low], data[:close])
      
      return return_all ? values : values&.last
    end
    
    def minus_di(data, time_period: 14, return_all: false)
      values      =   MinusDI.new(time_period: time_period).run(data[:high], data[:low], data[:close])
      
      return return_all ? values : values&.last
    end
    
    def plus_di(data, time_period: 14, return_all: false)
      values      =   PlusDI.new(time_period: time_period).run(data[:high], data[:low], data[:close])
      
      return return_all ? values : values&.last
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
    def bollinger_bands(data, time_period: 10, deviations_up: 2, deviations_down: 2, ma_type: :sma, return_all: false)
      bands         =   Bbands.new(time_period: time_period, deviations_up: deviations_up, deviations_down: deviations_down, ma_type: ma_constant(ma_type)).run(data[:close])      
      upper         =   bands[:out_real_upper_band]
      middle        =   bands[:out_real_middle_band]
      lower         =   bands[:out_real_lower_band]
      
      recent_upper  =   upper.last
      recent_middle =   middle.last
      recent_lower  =   lower.last
      
      return return_all ? {upper: upper, middle: middle, lower: lower} : {upper: recent_upper, middle: recent_middle, lower: recent_lower}
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
    def macd(data, fast_period: 12, slow_period: 26, signal_period: 9, return_all: false)
      return INVALID_DATA_ERROR if !valid_parameters(data: data, keys: [:close], required_size: slow_period)
      
      macds         =   Macd.new(fast_period: fast_period, slow_period: slow_period, signal_period: signal_period).run(data[:close])
      macd_raw      =   macds[:out_macd]
      macd_signal   =   macds[:out_macd_signal]
      macd_hist     =   macds[:out_macd_hist]
      
      return INVALID_DATA_ERROR if macds.nil? || macds.empty? || macd_raw.nil? || macd_raw.empty? || macd_signal.nil? || macd_signal.empty?
      
      return return_all ? {raw: macd_raw, signal: macd_signal, hist: macd_hist} : {raw: macd_raw.last, signal: macd_signal.last, hist: macd_hist.last}
    end
    
    # MACD indicator with controllable types and tweakable periods.
    def macd_ext(data, fast_period: 12, fast_ma: :sma, slow_period: 26, slow_ma: :sma, signal_period: 9, signal_ma: :sma, return_all: false)
      macd_exts     =   MacdExt.new(fast_period: fast_period, fast_ma: ma_constant(fast_ma), slow_period: slow_period, slow_ma: ma_constant(slow_ma), signal_period: signal_period, signal_ma: ma_constant(signal_ma)).run(data[:close])
      macd_raw      =   macd_exts[:out_macd]
      macd_signal   =   macd_exts[:out_macd_signal]
      macd_hist     =   macd_exts[:out_macd_hist]
      
      return return_all ? {raw: macd_raw, signal: macd_signal, hist: macd_hist} : {raw: macd_raw.last, signal: macd_signal.last, hist: macd_hist.last}
    end
    
    # Relative Strength Index indicator as a buy/sell signal.
    #
    # Similar to the stochastic in that it indicates overbought and oversold conditions.
    # When RSI is above 70, it means that the market is overbought and we should look to sell.
    # When RSI is below 30, it means that the market is oversold and we should look to buy.
    # RSI can also be used to confirm trend formations. If you think a trend is forming, wait for
    # RSI to go above or below 50 (depending on if you’re looking at an uptrend or downtrend) before you enter a trade.
    #
    def rsi(data, time_period: 14, return_all: false)
      return INVALID_DATA_ERROR if !valid_parameters(data: data, keys: [:close], required_size: time_period)
      
      values    =   Rsi.new(time_period: time_period).run(data[:close])
      
      return return_all ? values : values&.last&.round(0)&.to_i
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
    def stoch(data, fast_k_period: 13, slow_k_period: 3, slow_k_ma: :sma, slow_d_period: 3, slow_d_ma: :sma, return_all: false)
      stochs            =   Stoch.new(fast_k_period: fast_k_period, slow_k_period: slow_k_period, slow_k_ma: ma_constant(slow_k_ma), slow_d_period: slow_d_period, slow_d_ma: ma_constant(slow_d_ma)).run(data[:high], data[:low], data[:close])
      slow_ks           =   stochs[:out_slow_k]
      slow_ds           =   stochs[:out_slow_d]
      current_slow_k    =   slow_ks.last
      current_slow_d    =   slow_ds.last
      
      return return_all ? {slow_k: slow_ks, slow_d: slow_ds} : {slow_k: current_slow_k, slow_d: current_slow_d}
    end
    
    # fast stoch
    def stoch_f(data, fast_k_period: 13, fast_d_period: 3, fast_d_ma: :sma, return_all: false)
      stochfs           =   StochF.new(fast_k_period: fast_k_period, fast_d_period: fast_d_period, fast_d_ma: ma_constant(fast_d_ma)).run(data[:high], data[:low], data[:close])
      fast_ks           =   stochfs[:out_fast_k]
      fast_ds           =   stochfs[:out_fast_d]
      
      return return_all ? {fast_k: fast_ks, fast_d: fast_ds} : {fast_k: fast_ks&.last, fast_d: fast_ds&.last}
    end
    
    # created based on calculation here
    # https://www.tradingview.com/wiki/Awesome_Oscillator_(AO)
    # AO = SMA(High+Low)/2, 5 Periods) - SMA(High+Low/2, 34 Periods)
    #
    # a momentum indicator
    # This function just watches for zero-line crossover.
    #
    def awesome_oscillator(data, long_period: 34, short_period: 5, return_all: false)
      data[:mid]    =   []
      
      data[:high].each_with_index do |value, index|
        data[:mid] << ((value - data[:low][index]) / 2)
      end
      
      mas           =   {
        1 => sma(data[:mid], time_period: short_period),
        2 => sma(data[:mid], time_period: long_period)
      }
      
      current_mid   =   data[:mid].pop
      
      mas.merge!({
        3 => sma(data[:mid], time_period: short_period),
        4 => sma(data[:mid], time_period: long_period)
      })
      
      ma_prev       =   (mas[3].last - mas[4].last)
      ma_current    =   (mas[1].last - mas[2].last)
      
      return {previous: ma_prev, current: ma_current}
    end
    
    # Money flow index
    def mfi(data, time_period: 14, return_all: false)
      values        =   Mfi.new(time_period: time_period).run(data[:high], data[:low], data[:close], data[:volume])
      
      return return_all ? values : values&.last&.round(0)&.to_i
    end
    
    #
    #   On Balance Volume
    #   http://stockcharts.com/school/doku.php?id=chart_school:technical_indicators:on_balance_volume_obv
    #   signal assumption that volume precedes price on confirmation, divergence and breakouts
    #
    #   use with mfi to confirm
    #
    #   DOES NOT CURRENTLY WORK WITH RUBY TA-LIB - custom Ruby solution implemented instead
    #   Issue: https://github.com/rivella50/talib-ruby/issues/15
    # 
    def obv(data, return_all: true)
      obvs              =   []
      prev_closes       =   []
      
      data[:volume].each_with_index do |vol, index|
        current_close   =     data[:close][index]
        prev_close      =     prev_closes.last
        
        if index == 0
          obvs         <<   vol
        else
          if current_close > prev_close
            obvs       <<   (obvs.last + vol)
          elsif current_close < prev_close
            obvs       <<   (obvs.last - vol)
          elsif current_close == prev_close
            obvs       <<   obvs.last
          end
        end
        
        prev_closes    <<   current_close
      end
      
      return return_all ? obvs : obvs&.last
    end

    #
    #  Parabolic Stop And Reversal (SAR)
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
    def parabolic_sar(data, acceleration_factor: 0.02, maximum: 0.02, return_all: true)
      values        =   Sar.new(acceleration_factor: acceleration_factor, af_maximum: maximum).run(data[:high], data[:low])
      
      return return_all ? values : values&.last
    end
    
    #   Commodity Channel Index   
    def cci(data, time_period: 14, return_all: false)
      values        =   Cci.new(time_period: time_period).run(data[:high], data[:low], data[:close])
      
      return return_all ? values : values&.last&.round(0)&.to_i
    end
    
    #   Chande Momentum Oscillator 
    def cmo(data, time_period: 14, return_all: false)
      values        =   Cmo.new(time_period: time_period).run(data[:close])
      
      return return_all ? values : values&.last&.round(0)&.to_i
    end
    
    #   Chande Momentum Oscillator 
    def aroon_osc(data, time_period: 14, return_all: false)
      values        =   AroonOsc.new(time_period: time_period).run(data[:high], data[:low])
      
      return return_all ? values : values&.last&.round(0)&.to_i
    end
    
    #
    #  Stochastic - relative strength index
    #    
    #  TA-libs stoch_rsi function seems to be broken, use regular RSI method and then calculate StochRSI
    # 
    def stoch_rsi(data, time_period: 14, return_all: false)
      rsis            =   rsi(data, time_period: time_period, return_all: true)
      stochrsis       =   []
      
      rsis.each_with_index do |rsi, index|
        if (index+1) >= time_period
          start       =   (index + 1 - time_period)
          sub         =   rsis[start, time_period]
          max, min    =   sub.max, sub.min
          avg         =   ((rsi-min)/(max-min)).round(2)
          stochrsis  <<   avg
        end
      end
      
      return return_all ? stochrsis : stochrsis.last
    end
    
    #
    # Price Rate of Change
    # ROC = [(Close - Close n periods ago) / (Close n periods ago)] * 100
    # Positive values that are greater than 30 are generally interpreted as indicating overbought conditions,
    # while negative values lower than negative 30 indicate oversold conditions.
    #
    def roc(data, time_period: 14, return_all: false)
      values          =   Roc.new(time_period: time_period).run(data[:close])
      
      return return_all ? values : values.last
    end
    
    #
    #  Williams R%
    #  %R = (Highest High – Closing Price) / (Highest High – Lowest Low) x -100
    #  When the indicator produces readings from 0 to -20, this indicates overbought market conditions.
    #  When readings are -80 to -100, it indicates oversold market conditions.
    #
    def will_r(data, time_period: 14, return_all: false)
      values        =   WillR.new(time_period: time_period).run(data[:high], data[:low], data[:close])
      
      return return_all ? values : values.last
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
    def ult_osc(data, first_period: 7, second_period: 14, third_period: 28, return_all: false)
      values        =   UltOsc.new(first_period: first_period, second_period: second_period, third_period: third_period).run(data[:high], data[:low], data[:close])
      
      return return_all ? values : values.last
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
    def hli(data, time_period: 28, ma_period: 10, return_all: false)
      rhp             =   []
      total           =   data[:high].size
      
      0.upto(total-1).each do |index|
        slices_high   =   data[:high][index, time_period]
        slices_low    =   data[:low][index, time_period]
        
        high          =   0
        total_highs   =   0
        
        slices_high.each do |slice|
          total_highs  +=   (slice > high) ? 1 : 0
          high          =   (slice > high) ? slice : high
        end
        
        low           =   slices_low.min
        total_lows    =   0
        
        slices_low.each do |slice|
          total_lows +=   (slice <= low) ? 1 : 0
          low         =   (slice <= low) ? slice : low
        end
        
        rhp          <<   ((total_highs.to_f / (total_highs.to_f + total_lows.to_f))*100)
      end
      
      values          =   sma(rhp, time_period: ma_period, return_all: true)
      
      return return_all ? values : values&.last&.round(0)&.to_i
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
      macds         =   macd(data, fast_period: macd_fast_period, slow_period: macd_slow_period, signal_period: macd_signal_period, return_all: false)
      macd          =   macds[:raw] - macds[:signal]
      
      ema_current   =   ema(data[:close], time_period: ema_period, return_all: false)
      
      current_high  =   data[:high].last
      current_low   =   data[:low].last
      
      bull_current  =   current_high - ema_current
      bear_current  =   current_low - ema_current
      
      return {macd: macd, ema: ema_current, bull: bull_current, bear: bear_current, high: current_high, low: current_low}
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
    def mmi(data)
      size        =   data[:close].size
      average     =   data[:close].sum.to_f / size.to_f
      nl, nh      =   0, 0
      current     =   0
      
      0.upto(size-1) do |index|
        if data[:close][index] > average && data[:close][index] > current
          nl     +=   1
        elsif data[:close][index] < average && data[:close][index] < current
          nh     +=   1
        end
        
        current   =   data[:close][index]
      end
      
      mmi         =   ((100 * (nl + nh))/(size-1))
      
      return mmi
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
    def ht_sine(data, return_all: true)
      values        =   HtSine.new.run(data[:close])
      sines         =   values[:out_sine]
      lead_sines    =   values[:out_lead_sine]
      
      return return_all ? {sine: sines, lead_sine: lead_sines} : {sine: sines.last, lead_sine: lead_sines.last}
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
    def ht_trend_line(data, wma_period: 4)
      htl           =   HtTrendline.new.run(data[:close])
      wma           =   wma(data[:close], time_period: wma_period)
      
      declared      =   0
      uptrend       =   0
      downtrend     =   0
      
      a_htl         =   []
      a_wma         =   []
      
      0.upto(5) do |index|
        a_htl      <<   htl.pop
        a_wma      <<   wma.pop
        
        uptrend    +=   (a_wma[index] > a_htl[index]) ? 1 : 0
        downtrend  +=   (a_wma[index] < a_htl[index]) ? 1 : 0
        declared    =   ((a_wma[index].to_f - a_htl[index].to_f) / a_htl[index].to_f)
      end
      
      return {uptrend: uptrend, downtrend: downtrend, declared: declared}
    end
    
    #
    #
    #      Hilbert Transform - Trend vs Cycle Mode
    #      if > 1 then in trend mode ???
    #
    def ht_trend_mode(data, return_all: false)
      values      =   HtTrendMode.new.run(data[:close])
      
      return return_all ? values : values.last
    end
    
  end
end
