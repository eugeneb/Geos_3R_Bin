function [ OUT ] = GEOS_3R_BIN_bin2num( IN, format )
%биты поступают от младьшего к старшему 
IN=str2num(dec2bin(IN)); % получили число в двоичном представление
 if(length(format)==length('double'))
 while(format=='double')
    A(1:64)=0;
    for(k=0:5)
        for(m=1:8) % мадьшие 48 бит мантиссы
            A(m+8*k)=fix(mod(IN(k+1),10^m)/10^(m-1));
        end
    end
    for(k=1:4) % старшие 4 бита мантиссы
        A(48+k)=fix(mod(IN(7),10^k)/10^(k-1));     
    end
    for(k=1:4)%младшие биты порядка
        A(52+k)=fix(mod(IN(7),10^(k+4))/10^(k+3));
    end
    for(k=1:7)%старшие биты порядка
        A(56+k)=fix(mod(IN(8),10^k)/10^(k-1));
    end
    A(64)=fix(IN(8)/10^7);%знак
    
    OUT=(-1)^A(64);
    Man=0;%Мантисса
    for(k=1:52)
        Man=Man+A(53-k)*2^(-k);
    end
    expon=0;%порядок (экспонента)
    for(k=1:11) %порядок (экспонента)
        expon=expon+A(52+k)*2^(k-1);
    end
    OUT=OUT*(1+Man)*2^(expon-1023);
    
    break;
 end
 end
 
 if(length(format)==length('int'))
 while(format=='int')
    A(1:32)=0;
    for(k=1:4) % раскладываем число по битам
        for(m=1:8)
            A(m+8*(k-1))=fix(mod(IN(k),10^m)/10^(m-1));
        end
    end
    
    OUT=A(32); %формируем 
    for(k=1:31)% модуль числа             модуль=сумма(А(k)*2^(k-1)) - положительное число
        OUT=OUT+abs(A(k)-A(32))*2^(k-1); % модуль=1+сумма(|А(k)-1|*2^(k-1)) - отр. число
    end
    OUT=((-1)^A(32))*OUT; %учитываем знак
    
    break;
 end
 end

 if(length(format)==length('float'))
 while(format=='float')
    A(1:32)=0;
    for(k=0:3) % раскладываем число по битам
        for(m=1:8)
            A(m+8*k)=fix(mod(IN(k+1),10^m)/10^(m-1));
        end
    end
    
    Man=0; %мантисса
    for(k=1:23)
        Man=Man+A(24-k)*2^(-k);
    end
    
    expon=0; % порядок
    for(k=1:8)
        expon=expon+A(23+k)*2^(k-1);
    end
    
    OUT=(-1)^(A(32))*(1+Man)*2^(expon-127);
 break;
 end
 end
 
end

