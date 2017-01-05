function [ KAnumber, reliability, SignalToNoise, phase, Doppler, type] = GEOS_3R_BIN_DataDecod_0x10( IN )
%обрабатываетс€ сообщение одного спутника
% KAnumber - номер  ј
% GLONASSlitte - литера √ЋќЌј—— (дл€ GPS=0)
% reliability - достоверность фазовых измерений 0-достоврна
% SignalToNoise - отношение с/ш в полосе 1√ц в дЅ√ц
% phase - фаза несущей в циклах 
c=299792458;% скорость света [м/с]

in_bit=str2num(dec2bin(IN(1:4)));% по битам раскладываем первое слово
for(k=0:3)
    for(m=1:8)
        A(m+8*k)=fix(mod(in_bit(k+1),10^m)/10^(m-1));
    end
end

reliability=A(7)+A(8)*2;

KAnumber=0;
for(k=1:8)
    KAnumber=KAnumber+A(16+k)*2^(k-1);
end

SignalToNoise=GEOS_3R_BIN_bin2num(IN(5:8),'float');
phase=GEOS_3R_BIN_bin2num(IN(33:40),'double');
Doppler=GEOS_3R_BIN_bin2num(IN(17:24),'double');

    
end

