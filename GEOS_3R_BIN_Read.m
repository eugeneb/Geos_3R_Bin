function [ data, datN ] = GEOS_3R_BIN_Read( ncmd, com_port)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
preamble_and_ncmd(1:8,1)=[hex2dec('47'); hex2dec('45'); hex2dec('4f'); hex2dec('53'); ...
    hex2dec('72'); hex2dec('33'); hex2dec('50'); hex2dec('53')]; %преамбула GEOS-3R
ncmd=str2num(dec2bin(ncmd)); %добавляем к преамбуле номер сообщения (ncmd)
preamble_and_ncmd(9:10,1)=0;%!!! preamble_and_ncmd(10,1)==0 согласно протоколу
for(k=1:8)
    preamble_and_ncmd(9,1)=preamble_and_ncmd(9,1)+fix(mod(ncmd,10^k)/10^(k-1))*2^(k-1);
end
while(1==1)% читаем из порта, пока не найдем нужное сообщение
    if(fread(com_port,1,'uint8')==preamble_and_ncmd(1,1))%побайтово
    if(fread(com_port,1,'uint8')==preamble_and_ncmd(2,1))%ищем начало
    if(fread(com_port,1,'uint8')==preamble_and_ncmd(3,1))%нужного 
    if(fread(com_port,1,'uint8')==preamble_and_ncmd(4,1))%сообщения
    if(fread(com_port,1,'uint8')==preamble_and_ncmd(5,1))
    if(fread(com_port,1,'uint8')==preamble_and_ncmd(6,1))
    if(fread(com_port,1,'uint8')==preamble_and_ncmd(7,1))
    if(fread(com_port,1,'uint8')==preamble_and_ncmd(8,1))
    if(fread(com_port,1,'uint8')==preamble_and_ncmd(9,1))
    if(fread(com_port,1,'uint8')==preamble_and_ncmd(10,1))
        datN=fread(com_port,1,'uint8');%число слов в сообщении
        datN=datN+fread(com_port,1,'uint8')*(2^8);
        for(k=1:datN)%информационые слова сообщения
            data(4*(k-1)+1:4*k,1)=fread(com_port,4,'uint8');
        end
        ControlSum(1:4,1)=fread(com_port,4,'uint8');%контрольная сумма
        %обработка. проверяем cs
        ControlSum(1:4,1)=str2num(dec2bin(ControlSum(1:4,1)));
        for(k=1:4) %сонтрольную сумму по битам раскладываем
            for(m=1:8)
                bit_ControlSum(1,m+8*(k-1))=mod(fix(ControlSum(k)/10^(8-m)),10);
            end
        end
        % для расчета cs, понадобится создать массив, содержащий переамбулу,ncmd,datN, data; 
        dataFORbit(1:10,1)=preamble_and_ncmd(1:10,1); %1. всё в один массив
        dataFORbit(11,1)=datN-256*fix(datN/256); %???? не на 100% уверен
        dataFORbit(12,1)=fix(datN/256); %????
        dataFORbit(13:12+length(data),1)=data(1:end,1); %2. (для удобства)
        dataFORbit=str2num(dec2bin(dataFORbit)); % в бинарную систему счисления
        for(k=1:length(dataFORbit)) % делаем из каждого байта строку бит и формируем такой массив
            for(m=1:8)
                stroka=fix((k-1)/4)+1;
                stolb=m+8*(k-1-4*(stroka-1));
                bit_data(stroka,stolb)=mod(fix(dataFORbit(k)/10^(8-m)),10);
            end
        end
        size_bit_data=size(bit_data);
        for(m=1:size_bit_data(2)) %считаем контрольную сумму
            bit_cs(m)=bit_data(1,m);
            for(k=2:size_bit_data(1))
                bit_cs(m)=xor(bit_cs(m),bit_data(k,m));
            end
        end
        if(bit_cs(:)==bit_ControlSum(:)) % условиевыхода из зацикливания и окончания работы функции
            break; 
        end
    end
    end
    end
    end
    end
    end
    end
    end
    end
    end
end
end

