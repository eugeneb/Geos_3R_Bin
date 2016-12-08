function [ncmd, ndat, data] = GEOS_GetPacket(stream)
% function [ncmd, ndat, data] = GEOS_GetPacket(stream)
% 
% Данная функция читает из входного потока пакет с требуемого типа
% Входные параметры:
%   stream  - входной поток данных (файл или порт)
% Выходные параметры:
%   ncmd    - тип пакета
%   ndat    - количество прочитанных данных
%   data    - содержимое (uint32)
    
    ncmd = 0;
    ndat = 0;
    data = [];
    
    
    %%pream = char(['GEOSr3PS' ncmd]);        % Преамбула с номером команды
    pream = 'GEOSr3PS'; %'GEOSr3PS';  % Преамбула без номера команды
    if (~feof(stream))
        buf = char(fread(stream, length(pream), 'uint8')');
    else
        return;
    end

    CS = 0;
    CS0 = 1;
    
    while (CS ~= CS0)  % Читаем пакеты до тех пор, пока не совпадёт контрольная сумма
        
        % Ждём появления пакета
        while (strcmp(buf, pream) ~= 1)
            if (~feof(stream))
                buf = [buf(2:end) char(fread(stream, 1, 'char'))' ];
            else
                return;
            end
        end
        
        % Номер пакета
        if (~feof(stream))
            ncmd = fread(stream, 1, 'uint16');
        else
            return;
        end

        % Длина пакета
        if (~feof(stream))
            ndat = fread(stream, 1, 'uint16');
        else
            return;
        end

        % Чтение данных
        % Протокол Geos3 ориентирован на 32-битные слова
        if (~feof(stream))
            data = fread(stream, ndat, 'uint32');
        else
            return;
        end
        if (length(data) ~= ndat)
            return
        end
        
        % Чтение контрольной суммы
        if (~feof(stream))
            CS = fread(stream, 1, 'uint32');
        else
            return
        end

        % Расчёт контрольной суммы
        CS0 = getCS(pream, ncmd, ndat, data);
    end    
    
end

function [CS] = getCS(pream, ncmd, ndat, data)
    
    % Little endian !!!
    CS = uint32( pream(4)*2^24 + pream(3)*2^16 + pream(2)*2^8 + pream(1) );
    CS = bitxor(CS, uint32( pream(8)*2^24 + pream(7)*2^16 + pream(6)*2^8 + pream(5) ));

    ncmdndat = uint32( floor(ndat/2^8)*2^24 + mod(ndat, 2^8)*2^16 + floor(ncmd/2^8)*2^8 + mod(ncmd, 2^8)*2^0);
    CS = bitxor(CS, ncmdndat);
    
    for i=1:length(data)
        CS = bitxor(CS, uint32(data(i)));
    end
end