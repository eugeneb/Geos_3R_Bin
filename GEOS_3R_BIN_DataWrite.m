function [] = GEOS_3R_BIN_DataWrite( IN, COM_port)
% добавляет преамбулу и формирует проверочные биты сообщения
%(как побитовое исключающее или) и отправляет сообщения в COM порт
% на входе вектор столбец содержащий ncmd, datN, data 
%(32-битовые слова от младьшего к старшему байту)
data(1:8,1)=[hex2dec('47'); hex2dec('45'); hex2dec('4f'); hex2dec('53'); ...
    hex2dec('72'); hex2dec('33'); hex2dec('50'); hex2dec('53')]; %преамбула GEOSr3PS 
data(9:length(IN)+8,1)=IN(1:end,1);
N=length(data);

IN=str2num(dec2bin(data)); % в "бинарный" код
 for(k=1:N)
    for(m=1:8)
        stroka=fix((k-1)/4)+1;
        stolb=8*(k-1)+m-32*(stroka-1);
        A_bit(stroka,stolb)=fix(mod(IN(k),10^m)/10^(m-1));
    end
 end
 A_size=size(A_bit);
 for(m=1:A_size(2))
     cs_bit(m)=A_bit(1,m);
     for(k=2:A_size(1))
        cs_bit(m)=xor(cs_bit(m),A_bit(k,m));
     end
 end
 

 for(k=1:4)
     cs(k)=0;
     for(m=1:8)
        cs(k)=cs(k)+cs_bit(m+8*(k-1))*2^(m-1);
     end
 end
 for(k=1:4)
    data(N+k)=cs(k);
 end
 
 COM_port
 
 % fopen(COM_port);
 fwrite(COM_port, data);
 % fclose(COM_port);

end

