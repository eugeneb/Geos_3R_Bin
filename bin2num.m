function [ OUT ] = bin2num( IN, format )
% function [ OUT ] = bin2num( IN, format )
%
% Данная функция преобразует данные из символов в требуемый формат
% Входные параметры:
%    IN     - входное число
%    format - требуемый формат (double, int, float)
% Выходные параметры:
%    OUT    - выходное число
    

% Байты поступают от младшего к старшему (Little-endian)
        
    
    if strcmp(format, 'double')
        Input=IN;
        IN=str2num(dec2bin(IN)); % получили число в двоичном представлении

        Mant=0;
        expon=0;
        znak=0;
        for(k=1:6)
            Mant=Mant+Input(k)*2^(8*(k-1));
        end
        Mant=Mant+mod(Input(7),2^4)*2^48;
        Mant=Mant*2^-52;
        expon=fix(Input(7)/2^4);
        expon=expon+mod(Input(8),2^7)*2^4;
        znak=fix(Input(8)/2^7);
        OUT=(-1)^znak*(1+Mant)*2^(expon-1023);
    
    elseif strcmp(format, 'float')
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
        
    elseif strcmp(format, 'int8') || strcmp(format, 'int16') || strcmp(format, 'int32')
        OUT = 0;
        for i=1:length(IN)
            OUT = OUT + IN(i)*2^(8*(i-1));
        end
        
        if IN(end) > 2^7
            OUT = OUT - 2^(8*length(IN));
        end

    elseif strcmp(format, 'uint8') || strcmp(format, 'uint16') || strcmp(format, 'uint32')
        OUT = 0;
        for i=1:length(IN)
            OUT = OUT + IN(i)*2^(8*(i-1));
        end
    end
    


    
end

