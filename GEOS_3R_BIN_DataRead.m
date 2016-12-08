function [ data, datN ] = GEOS_3R_BIN_DataRead(ncmd, stream)
% function [ data, datN ] = GEOS_3R_BIN_DataRead(ncmd, stream)
% 
% Данная функция читает из входного потока пакет с требуемого типа
% Входные параметры:
%   ncmd    - тип требуемого пакета
%   stream  - входной поток данных (файл или порт)
% Выходные параметры:
%   data    - содержимое пакета (байты)
%   datN    - количество прочитанных данных
    
    
%считывает из указаного порта сообщение номер ncmd
% осуществляется проверка cs. На выходе: 
%data  - только информационные слова (БЕЗ преамбулы, datN,ncmd, cs)
%datN- колличество слов в сообщение (в это количество НЕ входят 
%преамбула, datN,ncmd, cs, Учитывается ТОЛЬКО data)
% preamble_and_ncmd(1:8,1)=[hex2dec('47'); hex2dec('45'); hex2dec('4f'); hex2dec('53'); ...
%     hex2dec('72'); hex2dec('33'); hex2dec('50'); hex2dec('53')]; %преамбула GEOS-3R
% ncmd=str2num(dec2bin(ncmd)); %добавляем к преамбуле номер сообщения (ncmd)
% preamble_and_ncmd(9:10,1)=0;%!!! preamble_and_ncmd(10,1)==0 согласно протоколу
% for(k=1:8)
%     preamble_and_ncmd(9,1)=preamble_and_ncmd(9,1)+fix(mod(ncmd,10^k)/10^(k-1))*2^(k-1);
% end
    
% Если ничего не будет выделено, можно просто выйти из функции со значениями по-умолчанию
    data = [];
    datN = 0;
    
    %%pream = char(['GEOSr3PS' ncmd]);        % Преамбула с номером команды
    pream = 'GEOSr3PS'; %'GEOSr3PS';  % Преамбула без номера команды
    if (~feof(stream))
        buf = char(fread(stream, length(pream), 'uint8')');
    else
        return;
    end

    % Ждём появления пакета
    while (strcmp(buf, pream) ~= 1)
        if (~feof(stream))
            buf = [buf(2:end) char(fread(stream, 1, 'char'))' ];
        else
            return;
        end
    end
    if (~feof(stream))
        cmd = fread(stream, 1, 'uint16');
    else
        return;
    end

    if (~feof(stream))
        ndat = fread(stream, 1, 'uint16');
    else
        return;
    end

    fprintf('ncmd: 0x%02X, ndat: %d\n', ncmd, ndat);

    if (~feof(stream))
        data = fread(stream, ndat, 'uint32');
    else
        return;
    end
    if (length(data) ~= ndat)
        return
    end
    
    if (~feof(stream))
        CS = fread(stream, 1, 'uint32');
    else
        return
    end

    CS0 = getCS(pream, ncmd, ndat, data);
    fprintf('CS: %08X %08X\n', uint32(CS), CS0);
    
    
    fprintf('data1: %d, CS: %08X %08X\n', length(data), CS, CS0);
    
% while(1==1)% читаем из порта, пока не найдем нужное сообщение
%     if(fread(stream,1,'uint8')==preamble_and_ncmd(1,1))%побайтово
%     if(fread(stream,1,'uint8')==preamble_and_ncmd(2,1))%ищем начало
%     if(fread(stream,1,'uint8')==preamble_and_ncmd(3,1))%нужного 
%     if(fread(stream,1,'uint8')==preamble_and_ncmd(4,1))%сообщения
%     if(fread(stream,1,'uint8')==preamble_and_ncmd(5,1))
%     if(fread(stream,1,'uint8')==preamble_and_ncmd(6,1))
%     if(fread(stream,1,'uint8')==preamble_and_ncmd(7,1))
%     if(fread(stream,1,'uint8')==preamble_and_ncmd(8,1))
%     if(fread(stream,1,'uint8')==preamble_and_ncmd(9,1))
%     if(fread(stream,1,'uint8')==preamble_and_ncmd(10,1))
        
%         datN=fread(stream,1,'uint8');%число слов в сообщении
%         datN=datN+fread(stream,1,'uint8')*(2^8);
%         for(k=1:datN)%информационые слова сообщения
%             data(4*(k-1)+1:4*k,1)=fread(stream,4,'uint8');
%         end
%         ControlSum(1:4,1)=fread(stream,4,'uint8');%контрольная сумма
%         %обработка. проверяем cs
%         ControlSum(1:4,1)=str2num(dec2bin(ControlSum(1:4,1)));
%         for(k=1:4) %сонтрольную сумму по битам раскладываем
%             for(m=1:8)
%                 bit_ControlSum(1,m+8*(k-1))=mod(fix(ControlSum(k)/10^(8-m)),10);
%             end
%         end
%         % для расчета cs, понадобится создать массив, содержащий переамбулу,ncmd,datN, data; 
%         dataFORbit(1:10,1)=preamble_and_ncmd(1:10,1); %1. всё в один массив
%         dataFORbit(11,1)=datN-256*fix(datN/256); %???? не на 100% уверен
%         dataFORbit(12,1)=fix(datN/256); %????
%         dataFORbit(13:12+length(data),1)=data(1:end,1); %2. (для удобства)
%         dataFORbit=str2num(dec2bin(dataFORbit)); % в бинарную систему счисления
%         for(k=1:length(dataFORbit)) % делаем из каждого байта строку бит и формируем такой массив
%             for(m=1:8)
%                 stroka=fix((k-1)/4)+1;
%                 stolb=m+8*(k-1-4*(stroka-1));
%                 bit_data(stroka,stolb)=mod(fix(dataFORbit(k)/10^(8-m)),10);
%             end
%         end
%         size_bit_data=size(bit_data);
%         for(m=1:size_bit_data(2)) %считаем контрольную сумму
%             bit_cs(m)=bit_data(1,m);
%             for(k=2:size_bit_data(1))
%                 bit_cs(m)=xor(bit_cs(m),bit_data(k,m));
%             end
%         end
%         if(bit_cs(:)==bit_ControlSum(:)) % условиевыхода из зацикливания и окончания работы функции
%             break; 
%         end
%     end
%     end
%     end
%     end
%     end
%     end
%     end
%     end
%     end
%     end
% end
% end

end

function [CS] = getCS(pream, ncmd, ndat, data)
    
    % Little endian !!!
    CS = uint32( pream(4)*2^24 + pream(3)*2^16 + pream(2)*2^8 + pream(1) );
    fprintf(' 1: %08X\n', CS);
    fprintf('  : %08X\n', uint32( pream(8)*2^24 + pream(7)*2^16 + pream(6)*2^8 + pream(5) ));
    CS = bitxor(CS, uint32( pream(8)*2^24 + pream(7)*2^16 + pream(6)*2^8 + pream(5) ));
    fprintf(' 2: %08X\n', CS);
    

    ncmdndat = uint32( mod(ndat, 2^8)*2^16 + floor(ndat/2^8)*2^24 + mod(ncmd, 2^8)*2^0 + floor(ncmd/2^8)*2^8 );
    fprintf('  : %08X\n', ncmdndat);
    CS = bitxor(CS, ncmdndat);
    fprintf(' 3: %08X\n', CS);
    
    for i=1:length(data)
        if (i<3)
            fprintf(' %d: %08X\n', i+3, uint32(data(i)));
        end

        CS = bitxor(CS, uint32(data(i)));
    end
end