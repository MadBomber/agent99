require 'quick'
require 'bm_report'

module AiAgent; end

require_relative 'lib/ai_agent/timestamp'

TS  = AiAgent::Timestamp
now = AiAgent::Timestamp.new
MS  = now.to_i
NOW = now.to_utc


def bm(how_many=1_000_000)
  result  = []
  result << quick(how_many, 'utc2ts')     { TS.utc2ts    }
  result << quick(how_many, 'bs_utc2ts')  { TS.bs_utc2ts }
  result << quick(how_many, 'ts2utc')     { TS.ts2utc(MS)     }
  result <<= quick(how_many, 'bs_ts2utc') { TS.bs_ts2utc(MS)  }

  result
end 

bm_report bm


__END__

┌────────┬─────────┬───────────┬─────────┬───────────┐
│ Label  │ utc2ts  │ bs_utc2ts │ ts2utc  │ bs_ts2utc │
├────────┼─────────┼───────────┼─────────┼───────────┤
│ cstime │ 0.0     │ 0.0       │ 0.0     │ 0.0       │
│ cutime │ 0.0     │ 0.0       │ 0.0     │ 0.0       │
│ stime  │ 0.0     │ 1.0e-05   │ 9.0e-05 │ 0.0       │
│ utime  │ 6.0e-05 │ 6.0e-05   │ 0.00254 │ 0.00013   │
│ real   │ 6.0e-05 │ 8.0e-05   │ 0.00263 │ 0.00013   │
│ total  │ 6.0e-05 │ 8.0e-05   │ 0.00263 │ 0.00013   │
└────────┴─────────┴───────────┴─────────┴───────────┘
