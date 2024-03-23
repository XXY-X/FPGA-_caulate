module control
(
input					clk_in,			//系统时钟
input					rst_n_in,		//系统复位，低有效
	
input	wire		[15:0]	key_out,			//按键
input	wire [15:0]	key_pulse,

	
output	reg	[3:0]	seg_data_1,		//SEG1 数码管要显示的数据
output	reg	[3:0]	seg_data_2,		//SEG2 数码管要显示的数据
output	reg	[3:0]	seg_data_3,		//SEG3 数码管要显示的数据
output	reg	[3:0]	seg_data_4,		//SEG4 数码管要显示的数据
output	reg	[3:0]	seg_data_5,		//SEG5 数码管要显示的数据
output	reg	[3:0]	seg_data_6,		//SEG6 数码管要显示的数据
output	reg	[3:0]	seg_data_7,		//SEG7 数码管要显示的数据
output	reg	[3:0]	seg_data_8,		//SEG8 数码管要显示的数据
output	reg	[7:0]	seg_data_en,	//各位数码管数据显示使能，[MSB~LSB]=[SEG8~SEG1]
output	reg	[7:0]	seg_dot_en		//各位数码管小数点显示使能，[MSB~LSB]=[SEG8~SEG1]
);
reg [15:0] num;
reg [3:0] state;
parameter STATE0 = 4'b0_000;//空闲，完成计算且已显示或未开始计算
parameter STATE1 = 4'b0_001;//按下第一个计算数，需完成的操作：清除上一次存的所有数据及显示使能，显示第一个计算数并拼接成两位数
parameter STATE2 = 4'b0_010;//按下操作符，需完成的操作：清除上一次的显示使能，储存操作符
parameter STATE3 = 4'b0_011;//按下第二个计算数，需完成的操作：显示第二个计算数并拼接成两位数
parameter STATE4 = 4'b0_100;//进行加减乘计算
parameter STATE5 = 4'b0_101;//进行除法运算
parameter DONE   = 4'b1_000;//运算完并成功显示

reg flag_num;//按下一次数字置1，空闲状态都是0；
reg flag_sign;//按下一次运算符置1一次，空闲状态为0
reg flag_equal;//按下一次等于号置1一次，空闲状态为0

//状态跳转
always@(posedge clk_in or negedge rst_n_in) begin
    if(!rst_n_in)
        state <= STATE0;
    else
        case(state)
            STATE0 : state <=(flag_num)? STATE1:STATE0; 
            STATE1 : state <=(flag_sign)?STATE2:STATE1; 
            STATE2 : state <=(flag_num)? STATE3:STATE2;
            STATE3 : state <=(flag_equal)?(    (sign==CHU)?STATE5:STATE4    ):STATE3;//根据符号跳转
            STATE4 : state <=(flag_done1)?DONE:STATE4;
            STATE5 : state <=(flag_done2)?DONE:STATE5;
            DONE   : state <= STATE0;
        endcase
end
///////////计算加减乘
reg flag_done1;//计算完后置1,在状态显示完后置0
reg [15:0] result1;
always@(posedge clk_in or negedge rst_n_in) begin
    if(!rst_n_in)begin
        result1<=0;   
        flag_done1<=0;
    end
    else if(state==STATE4)begin
        if(sign==JIA)begin
            result1<=num1 + num2;
            flag_done1<=1;
        end
        else if(sign==JIAN)begin
            if(num1>=num2)begin
                result1<=num1-num2;
                flag_done1<=1;
            end
            else begin
                result1<=num2-num1;
                flag_done1<=1;
            end
        end
        else if(sign==CHENG)begin
            result1<=num1*num2;
            flag_done1<=1;
        end
    end
    else if(result1_temp==0)begin//显示完毕，置0跳出显示区 
            flag_done1<=0;
    end
end

///////////计算除法
reg flag_done2;//计算完后置1，在显示完后置0
reg [3:0] result2_int1;//十位部分：0~9.开始时归0
reg [3:0] result2_int2;//个位部分：0~9.开始时归0
reg [3:0] result2_float [7:0];//小数点后7位:1~7,不用第一位
reg [3:0] result2_index;//开始时归0
reg temp;//置1表示临时变量已赋值，置0则没有；计算结束后归0
reg temp2;//置1表示处理小数部分临时变量已赋值，置0则没有.计算结束后归0
reg [15:0]num1_temp;//开始时会覆盖
reg [15:0]num2_temp;//开始时会覆盖
reg [15:0]num_float_temp;//会覆盖

always@(posedge clk_in or negedge rst_n_in) begin
    if(!rst_n_in)begin
        result2_int1<=0;
        result2_int2<=0;
        result2_float[0]<=0;
        result2_float[1]<=0;
        result2_float[2]<=0;
        result2_float[3]<=0;
        result2_float[4]<=0;
        result2_float[5]<=0;
        result2_float[6]<=0;
        result2_float[7]<=0;
        result2_index<=0;
        temp<=0;
        temp2<=0;
        num1_temp<=0;
        num2_temp<=0;
        flag_done2<=0;
    end
    else if(state==STATE5)begin
        if(temp==0)begin
            num1_temp<=num1;
            num2_temp<=num2;
            temp<=1;
            result2_int1<=0;//清除上一次
            result2_int2<=0;
            result2_float[0]<=0;
            result2_float[1]<=0;
            result2_float[2]<=0;
            result2_float[3]<=0;
            result2_float[4]<=0;
            result2_float[5]<=0;
            result2_float[6]<=0;
            result2_float[7]<=0;
            result2_index<=0;
        end
        else begin
            if(num1_temp>=((16'd10)*num2_temp))begin//十位
                num1_temp<=num1_temp - ((16'd10)*num2_temp);
                result2_int1<=result2_int1+1;
            end
            else if(num1_temp>=num2_temp)begin//个位
                num1_temp<=num1_temp - num2_temp;
                result2_int2<=result2_int2+1;
            end
            else begin//小数
                if(temp2==0)begin
                    num_float_temp<=num1_temp;
                    temp2<=1;
                end
                else begin
                    if(num_float_temp<num2_temp)begin
                        num_float_temp<=(num_float_temp*(16'd10));
                        result2_index<=result2_index+4'd1;
                        if(result2_index==(4'd7))begin//除计算结束
                            flag_done2<=1;//跳出STATE5，等于跳出除计算
                            
                        end
                    end
                    else begin
                        num_float_temp<=num_float_temp - num2_temp;
                        result2_float[result2_index]<=result2_float[result2_index]+4'd1;
                    end
                end
            end
        end
        
    end
    else if(show2_flag==1)begin
        flag_done2<=0;//结束显示除结果循环
        temp<=0;
        temp2<=0;
    end
end


////////////显示数并且存储数
reg [1:0] cnt1;
reg [1:0] cnt2;
reg [15:0]num1;//无需清除，每次会覆盖
reg [15:0]num2;
reg [15:0]result1_temp;//临时放加减乘的结果，方便递减拆解个位十位
reg [1:0]result1_temp_cnt;//计数，确保临时变量只会被赋值一次
reg show2_flag;
always@(posedge clk_in or negedge rst_n_in) begin
    if(!rst_n_in)begin
        seg_data_en[0]<=0;
        seg_data_en[1]<=0;
        seg_data_en[2]<=0;
        seg_data_en[3]<=0;
        seg_data_en[4]<=0;
        seg_data_en[5]<=0;
        seg_data_en[6]<=0;
        seg_data_en[7]<=0;
        seg_data_1<=4'd0;
        seg_data_2<=4'd0;
        seg_data_3<=4'd0;
        seg_data_4<=4'd0;
        seg_data_5<=4'd0;
        seg_data_6<=4'd0;
        seg_data_7<=4'd0;
        seg_data_8<=4'd0;
        cnt1<=0;
        cnt2<=0;
        result1_temp_cnt<=0;
        result1_temp<=0;
        show2_flag<=0;
    end
    else if(state==STATE1)begin//显示第一个数
        if(cnt1==0)begin//一位数
        seg_data_8<=num;
        seg_data_en[0]<=1;
        seg_data_en[1]<=0;//清除上一次的显示使能
        seg_data_en[2]<=0;
        seg_data_en[3]<=0;
        seg_data_en[4]<=0;
        seg_data_en[5]<=0;
        seg_data_en[6]<=0;
        seg_data_en[7]<=0;
        seg_data_1<=4'd0;
        seg_data_2<=4'd0;
        seg_data_3<=4'd0;
        seg_data_4<=4'd0;
        seg_data_5<=4'd0;
        seg_data_6<=4'd0;
        seg_data_7<=4'd0;
        cnt1<=cnt1+1;
        num1<=num;
        end
        else if((cnt1==1) && (flag_num))begin//两位数
        seg_data_7<=seg_data_8;
        seg_data_8<=num;
        seg_data_1<=4'd0;
        seg_data_2<=4'd0;
        seg_data_3<=4'd0;
        seg_data_4<=4'd0;
        seg_data_5<=4'd0;
        seg_data_6<=4'd0;
        seg_data_en[0]<=1;
        seg_data_en[1]<=1;
        num1<=(num1*10)+(num);
        cnt1<=cnt1+1;//多按舍弃
        end
    end
    else if(state==STATE2)begin
        seg_data_en[0]<=0;//清除显示
        seg_data_en[1]<=0;
        seg_data_en[2]<=0;
        seg_data_en[3]<=0;
        seg_data_en[4]<=0;
        seg_data_en[5]<=0;
        seg_data_en[6]<=0;
        seg_data_en[7]<=0;
        seg_data_1<=4'd0;
        seg_data_2<=4'd0;
        seg_data_3<=4'd0;
        seg_data_4<=4'd0;
        seg_data_5<=4'd0;
        seg_data_6<=4'd0;
        seg_data_7<=4'd0;
        seg_data_8<=4'd0;
        cnt1<=0;//清除上一次第一个数的位数计次
        cnt2<=0;//清除上一次第二个数的位数计次
        show2_flag<=0;//清除上一次除的显示结束标志位
    end
    else if(state==STATE3)begin//显示第二个数
        if(cnt2==0)begin
            seg_data_8<=num;
            seg_data_1<=4'd0;
            seg_data_2<=4'd0;
            seg_data_3<=4'd0;
            seg_data_4<=4'd0;
            seg_data_5<=4'd0;
            seg_data_6<=4'd0;
            seg_data_7<=4'd0;
            seg_data_en[0]<=1;
            seg_data_en[1]<=0;//清除上一次的显示使能
            seg_data_en[2]<=0;
            seg_data_en[3]<=0;
            seg_data_en[4]<=0;
            seg_data_en[5]<=0;
            seg_data_en[6]<=0;
            seg_data_en[7]<=0;
            cnt2<=cnt2+1;
            num2<=num;
        end
        if((cnt2==1) && (flag_num))begin//两位数
            seg_data_7<=seg_data_8;
            seg_data_8<=num;
            seg_data_1<=4'd0;
            seg_data_2<=4'd0;
            seg_data_3<=4'd0;
            seg_data_4<=4'd0;
            seg_data_5<=4'd0;
            seg_data_6<=4'd0;
            seg_data_en[0]<=1;
            seg_data_en[1]<=1;
            num2<=(num2*10)+(num);
            cnt2<=cnt2+1;
        end
    end
    else if(flag_done1==1)begin//显示加减乘后的结果
        if(result1_temp_cnt==0)begin
            result1_temp<=result1;
            result1_temp_cnt<=result1_temp_cnt+2'd1;
            seg_data_en[0]<=0;
            seg_data_en[1]<=0;//清除上一次的显示使能
            seg_data_en[2]<=0;
            seg_data_en[3]<=0;
            seg_data_en[4]<=0;
            seg_data_en[5]<=0;
            seg_data_en[6]<=0;
            seg_data_en[7]<=0;
            seg_data_1<=4'd0;
            seg_data_2<=4'd0;
            seg_data_3<=4'd0;
            seg_data_4<=4'd0;
            seg_data_5<=4'd0;
            seg_data_6<=4'd0;
            seg_data_7<=4'd0;
            seg_data_8<=4'd0;
        end
        else begin
            if(result1_temp>=15'd1000)begin
                result1_temp<=result1_temp - 15'd1000;
                seg_data_5<=seg_data_5 + 4'd1;
               
            end
            else if(result1_temp>=15'd100)begin
                result1_temp<=result1_temp - 15'd100;
                seg_data_6<=seg_data_6 + 4'd1;
            end
            else if(result1_temp>=15'd10)begin
                result1_temp<=result1_temp - 15'd10;
                seg_data_7<=seg_data_7 + 4'd1;
            end
            else if(result1_temp>=15'd1)begin//最后一个个位数，显示完毕
                result1_temp<=result1_temp - 15'd1;
                seg_data_8<=seg_data_8 + 4'd1;
            end
            else begin
                if((num1<num2)&&(sign==JIAN))begin//负数
                    if(result1>=15'd10)begin
                        seg_data_en<=8'b0000_0111;
                        seg_data_6<=4'd10;//负号
                    end
                    else begin
                        seg_data_en<=8'b0000_0011;
                        seg_data_7<=4'd10;//负号
                    end
                end
                else begin//正数
                    if(result1>=15'd1000)begin
                        seg_data_en<=8'b0000_1111;
                    end
                    else if(result1>=15'd100)begin
                        seg_data_en<=8'b0000_0111;
                    end
                    else if(result1>=15'd10)begin
                        seg_data_en<=8'b0000_0011;
                    end
                    else begin
                        seg_data_en<=8'b0000_0001;
                    end
                end
                result1_temp_cnt<=0;//显示完毕，计数器清零，避免影响下次显示
            end
        end
    end
    else if(flag_done2==1)begin//显示除后的结果
        if(result2_int1==0)begin
            seg_data_1<=result2_int2;
            seg_data_2<=result2_float[1];
            seg_data_3<=result2_float[2];
            seg_data_4<=result2_float[3];
            seg_data_5<=result2_float[4];
            seg_data_6<=result2_float[5];
            seg_data_7<=result2_float[6];
            seg_data_8<=result2_float[7];
            seg_data_en<=8'b1111_1111;
            seg_dot_en<=8'b1000_0000;
            show2_flag<=1;
        end
        else begin
            seg_data_1<=result2_int1;
            seg_data_2<=result2_int2;
            seg_data_3<=result2_float[1];
            seg_data_4<=result2_float[2];
            seg_data_5<=result2_float[3];
            seg_data_6<=result2_float[4];
            seg_data_7<=result2_float[5];
            seg_data_8<=result2_float[6];
            seg_data_en<=8'b1111_1111;
            seg_dot_en<=8'b0100_0000;
            show2_flag<=1;
        end
    end
end


//////////读取数据

reg [2:0]sign;//符号没有清除操作，会保留上一次参数，不过每次按下后会覆盖不用担心
parameter JIA=3'b0_00;
parameter JIAN=3'b0_01;
parameter CHENG=3'b0_10;
parameter CHU=3'b0_11;
always@(posedge clk_in or negedge rst_n_in) begin
	if(!rst_n_in) begin
    flag_num<=0;
    flag_sign<=0;
    flag_equal<=0;
    num<=0;
	end else  begin
	    if(key_pulse!=0)begin
    		case(key_out)
    			16'b1111111111110111: begin
                flag_sign<=1;sign<=CHU;end  //操作符/
    			16'b1111111111111011: begin 
    			flag_num<=1;num<=9;end  //9
    			16'b1111111111111101: begin 
    			flag_num<=1;num<=8;end  //8
    			16'b1111111111111110: begin 
    			flag_num<=1;num<=7;end  //7
    			16'b11111111_0111_1111: begin 
    			flag_sign<=1;sign<=CHENG;end  //操作符x
    			16'b11111111_1011_1111: begin 
    			flag_num<=1;num<=6;end  //6
    			16'b11111111_1101_1111: begin 
    			flag_num<=1;num<=5;end  //5
    			16'b11111111_1110_1111: begin 
    			flag_num<=1;num<=4;end  //4
    			16'b1111_0111_1111_1111: begin 
    			flag_sign<=1;sign<=JIAN;end  //操作符-
    			16'b1111_1011_1111_1111: begin 
    			flag_num<=1;num<=1;end  //1
    			16'b1111_1101_1111_1111: begin 
    			flag_num<=1;num<=2;end  //2
    			16'b1111_1110_1111_1111: begin 
    			flag_num<=1;num<=3;end  //3
    			16'b0111111111111111: begin
    			flag_sign<=1;sign<=JIA;end  //操作符+
    			16'b1011111111111111: begin 
    			flag_equal<=1;end  //操作符=
    			16'b1101111111111111: begin
    			end  //小数点
    			16'b1110111111111111: begin
    			flag_num<=1;num<=0;end  //0
    			default:begin //中间空闲状态
    			flag_num<=0;flag_sign<=0;flag_equal<=0;num<=num;end
    		endcase
		end
		else begin
		    flag_num<=0;flag_sign<=0;flag_equal<=0;num<=num;
		end
	end
end








endmodule