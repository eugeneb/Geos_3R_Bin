function [ OUT ] = bin2num( IN, format )
% function [ OUT ] = bin2num( IN, format )
%
% Данная функция преобразует данные из символов в требуемый формат
% Входные параметры:
%    IN     - входное число
%    format - требуемый формат (double, float, int8, uint8, ..., uint32)
% Выходные параметры:
%    OUT    - выходное число
    

% Байты поступают от младшего к старшему (Little-endian)
        
    
    if strcmp(format, 'double')
        Input=IN;

        Mant=0;
        expon=0;
        znak=0;
        for k=1:6
            Mant=Mant+Input(k)*2^(8*(k-1));
        end
        Mant=Mant+mod(Input(7),2^4)*2^48;
        Mant=Mant*2^-52;
        
        expon=fix(Input(7)/2^4);
        expon=expon+mod(Input(8),2^7)*2^4;
        
        znak=fix(Input(8)/2^7);
        OUT=(-1)^znak*(1+Mant)*2^(expon-1023);
    
    elseif strcmp(format, 'float')
        Input=IN;

        Mant=0;
        expon=0;
        znak=0;
        for k=1:2
            Mant=Mant+Input(k)*2^(8*(k-1));
        end
        Mant=Mant+mod(Input(3),2^7)*2^16;
        Mant=Mant*2^-23;
        
        expon=fix(Input(3)/2^7);
        expon=expon+mod(Input(4),2^7)*2^1;
        
        znak=fix(Input(4)/2^7);
        OUT=(-1)^znak*(1+Mant)*2^(expon-127);
        
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

