module Indicate
  module MovingAverages
    
    #
    # Simple Moving Average - SMA
    # 
    # A simple moving average (SMA) is an arithmetic moving average calculated by adding the closing price of the security for a number of time periods and then dividing this total by the number of time periods.
    # 
    # https://www.investopedia.com/terms/s/sma.asp
    # 
    def sma(data, time_period: 14, return_all: false)
      return moving_average(data, type: :sma, time_period: time_period, return_all: return_all)
    end
    
    #
    # Exponential Moving Average - EMA
    # An exponential moving average (EMA) is a type of moving average that is similar to a simple moving average, except that more weight is given to the latest data. 
    # It's also known as the exponentially weighted moving average. This type of moving average reacts faster to recent price changes than a simple moving average.
    #
    # https://www.investopedia.com/terms/e/ema.asp
    #
    def ema(data, time_period: 14, return_all: false)
      return moving_average(data, type: :ema, time_period: time_period, return_all: return_all)
    end
    
    #
    # Weighted Moving Average - WMA
    # 
    # A Weighted Moving Average puts more weight on recent data and less on past data. This is done by multiplying each bar’s price by a weighting factor. Because of its unique calculation, WMA will follow prices more closely than a corresponding Simple Moving Average.
    # 
    # https://www.fidelity.com/learning-center/trading-investing/technical-analysis/technical-indicator-guide/wma
    #
    def wma(data, time_period: 14, return_all: false)
      return moving_average(data, type: :wma, time_period: time_period, return_all: return_all)
    end
    
    # 
    # Double Exponential Moving Average - DEMA
    # 
    # The DEMA is a calculation based on both a single exponential moving average (EMA) and a double EMA
    # The DEMA is a fast-acting moving average that is more responsive to market changes than a traditional moving average. It was developed in an attempt to create a calculation that eliminated some of the lag associated with traditional moving averages.
    # 
    # https://www.investopedia.com/terms/d/double-exponential-moving-average.asp
    # 
    def dema(data, time_period: 14, return_all: false)
      return moving_average(data, type: :dema, time_period: time_period, return_all: return_all)
    end
    
    # 
    # Triple Exponential Moving Average - TEMA
    # 
    # A technical indicator used for smoothing price and other data. It is a composite of a single exponential moving average, a double exponential moving average and a triple exponential moving average.
    # 
    # The TEMA smooths price fluctuations and filters out volatility, thereby making it easier to identify trends with little lag. It is a useful tool in identifying strong, long lasting trends, but may be of limited use in range-bound markets with short term fluctuations.
    # 
    # https://www.investopedia.com/terms/t/triple-exponential-moving-average.asp
    #
    def tema(data, time_period: 14, return_all: false)
      return moving_average(data, type: :tema, time_period: time_period, return_all: return_all)
    end
    
    #
    # Triangular Moving Average - TRIMA
    # 
    # The Triangular Moving Average (TRIMA) represents an average of prices, but places weight on the middle prices of the time period. The calculations double-smooth the data using a window width that is one-half the length of the series.
    #
    # https://www.tradingtechnologies.com/help/x-study/technical-indicator-definitions/triangular-moving-average-trima/
    # 
    def trima(data, time_period: 14, return_all: false)
      return moving_average(data, type: :trima, time_period: time_period, return_all: return_all)
    end
    
    # 
    # Kaufman's Adaptive Moving Average - KAMA
    # 
    # Kaufman's Adaptive Moving Average (KAMA) is a moving average designed to account for market noise or volatility. KAMA will closely follow prices when the price swings are relatively small and the noise is low. KAMA will adjust when the price swings widen and follow prices from a greater distance. This trend-following indicator can be used to identify the overall trend, time turning points and filter price movements.
    # 
    # http://stockcharts.com/school/doku.php?id=chart_school:technical_indicators:kaufman_s_adaptive_moving_average
    # 
    def kama(data, time_period: 14, return_all: false)
      return moving_average(data, type: :kama, time_period: time_period, return_all: return_all)
    end
    
    # 
    # The Mother of Adaptive Moving Average - MAMA
    # 
    # The MESA Adaptive Moving Average (MAMA) adapts to price movement in an entirely new and unique way.  The adapation is based on the rate change of phase as measured by the Hilbert Transform Discriminator.
    # The advantage of this method of adaptation is that it features a fast attack average and a slow decay average so that composite average rapidly ratchets behind price changes and holds the average value until the next ratchet occurs.
    # 
    # https://www.prorealcode.com/prorealtime-indicators/john-ehlers-mama-the-mother-of-adaptive-moving-average/
    # 
    def mama(data, fast_limit: 0.5, slow_limit: 0.05, return_all: false)
      return nil if data.nil? || data.empty?
      
      values  =   Mama.new(fast_limit: fast_limit, slow_limit: slow_limit).run(data)
      mama    =   data[:out_mama]
      fama    =   data[:out_fama]
      
      return return_all ? {mama: mama, fama: fama} : {mama: mama&.last, fama: fama&.last}
    end
    
    # 
    # T3 Moving Average
    # 
    # The T3 Moving Average is considered superior to traditional moving averages as it is smoother, more responsive and thus performs better in ranging market conditions as well. However, it bears the disadvantage of overshooting the price as it attempts to realign itself to current market conditions
    # It incorporates a smoothing technique which allows it to plot curves more gradual than ordinary moving averages and with a smaller lag. Its smoothness is derived from the fact that it is a weighted sum of a single EMA, double EMA, triple EMA and so on. 
    # 
    # http://www.binarytribune.com/forex-trading-indicators/t3-moving-average-indicator/
    # 
    def t3(data, time_period: 5, volume_factor: 0.7, return_all: false)
      return nil if data.nil? || data.empty?
      
      t3s       =   T3.new(time_period: time_period, volume_factor: volume_factor).run(data)
      
      return return_all ? t3s : t3s&.last
    end
    
    def moving_average(data, type: :sma, time_period:, return_all: false)
      return nil if data.nil? || data.empty?
      
      values         =   case type.to_sym
        when :sma
          Sma.new(time_period: time_period).run(data)
        when :ema
          Ema.new(time_period: time_period).run(data)
        when :wma
          Wma.new(time_period: time_period).run(data)
        when :dema
          Dema.new(time_period: time_period).run(data)
        when :tema
          Tema.new(time_period: time_period).run(data)
        when :trima
          Trima.new(time_period: time_period).run(data)
        when :kama
          Kama.new(time_period: time_period).run(data)
        else
          Sma.new(time_period: time_period).run(data)
      end
      
      return return_all ? values : values&.last
    end
    
  end
end