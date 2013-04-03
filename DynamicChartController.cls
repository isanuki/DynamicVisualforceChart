public with sharing class DynamicChartController {

    public static final Integer MONTHS_OF_YEAR = 12;
    public String selectYear {get; set;}
    public List<SelectOption> yearList {get; set;}

    public DynamicChartController(){
        yearList = createYearList();
        selectYear = yearList.get(0).getValue();
    }
    
    public List<SelectOption> createYearList(){
        List<SelectOption> options = new List<SelectOption>();
        // 商談から年のﾘｽﾄを生成
        for(AggregateResult result : [SELECT CALENDAR_YEAR(CloseDate) year 
                                      FROM Opportunity 
                                      WHERE IsWon = true 
                                      GROUP BY CALENDAR_YEAR(CloseDate)
                                      ORDER BY CALENDAR_YEAR(CloseDate)]){
            options.add(new SelectOption(String.valueOf(result.get('year')),
                                         result.get('year')+'年'));
        }
        return options;
    }

    public List<ChartData> getData(){
        List<ChartData> dataList = new List<ChartData>();
        Map<Integer, Double>resultMap = new Map<Integer, Double>();
        
        // 勝ち商談の月ごとの合計値を月=>金額のMapに入れる
        for(AggregateResult result : [SELECT CALENDAR_MONTH(CloseDate) month, SUM(Amount) sumAmount 
                                      FROM Opportunity 
                                      WHERE CALENDAR_YEAR(CloseDate) =: Integer.valueOf(selectYear) 
                                            AND IsWon = true
                                      GROUP BY CALENDAR_MONTH(CloseDate)
                                      ORDER BY CALENDAR_MONTH(CloseDate)]){
            resultMap.put(Integer.valueOf(result.get('month')), 
                          Double.valueOf(result.get('sumAmount')));
        }
        
        // ｸﾞﾗﾌ表示用のﾃﾞｰﾀを12ヵ月分作成することで､商談に売上がない月でもｸﾞﾗﾌを出す
        for(Integer m=1; m <= MONTHS_OF_YEAR; m++){
            ChartData tmpData = new ChartData(m);
            if(null != resultMap.get(m)){
                tmpData.amount = resultMap.get(m);
            } else {
                tmpData.amount = 0;
            }
            dataList.add(tmpData);
        }
        return dataList;
    }
    
    public PageReference change(){
        return null;
    }
    
    public class ChartData{
        public Integer month{get; set;}
        public Double amount{get; set;}
        public ChartData(Integer month){
            this.month = month;
        }
    }
}
