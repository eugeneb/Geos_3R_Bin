clear
clc

%fclose(instrfind)
%настройки COM порта
Num_com_port='COM15';
baud=115200;
com_port=serial(Num_com_port, 'BaudRate', baud);

%что обрабатывать
settings.LatLonData=0; %сообщение 0х20. Базовый набор географических координат
settings.phData=1;     %сообщение 0х10.
phData.NumPointPlot=24; % число точек на графике
phData.chisl_spytnicov=130;% условно, с запасов - число спутников 

phData.reliable(1:phData.NumPointPlot,1:phData.chisl_spytnicov)=nan; 
phData.SignalToNoise(1:phData.NumPointPlot,1:phData.chisl_spytnicov)=nan;
phData.phase(1:phData.NumPointPlot,1:phData.chisl_spytnicov)=nan;
phData.time(1:phData.NumPointPlot)=nan;

Bin.preamble=[hex2dec('47'); hex2dec('45'); hex2dec('4f'); hex2dec('53'); ...
    hex2dec('72'); hex2dec('33'); hex2dec('50'); hex2dec('53')]; %преамбула GEOSr3PS

%настройки бинарного протокола приемника
for(k=1:8)
Bin.data_write(k)=Bin.preamble(k);
end
Bin.data_write(9:16)=[hex2dec('4F'), 0, 1, 0, 0, 0, hex2dec('01'), 0];
BinDataWrite(Bin.data_write, com_port);

StartTime=-1; % время начала работы

% цикл
for(cikl_for=1:phData.NumPointPlot)
    %считывание даннных из порта
    fopen(com_port);
    Bin.data_read=fread(com_port,512);
    Bin.data_read(end+1:1024)=fread(com_port,512);
    Bin.data_read(end+1:1536)=fread(com_port,512);
    Bin.data_read(end+1:2048)=fread(com_port,512);
    fclose(com_port);
    
    LatLonData.start=0;
    phData.start=0;
    
    Bin.Num_posts=0;% колличество полученных сообщений
    for(k=1:(length(Bin.data_read)-10)) % цикл поиска начала сообщения и их колличества
       logik_Matrix(1:8)=(Bin.data_read(k:k+7)==Bin.preamble(1:8));
       logik=logik_Matrix(1);
       for (ind=2:8)
            logik=logik&logik_Matrix(ind); 
       end
       
       if(logik)
           Bin.Num_posts=Bin.Num_posts+1; %инкремент колличства сообщений
           Bin.Num_start(Bin.Num_posts)=k;% ячейка начала сообщения
       end
    end
    
    if (Bin.Num_posts>0) % если сообщения получены из приемника
        Bin.datN=Bin.data_read(Bin.Num_start+11)*256+Bin.data_read(Bin.Num_start+10); %количество слов в сообщение 
        Bin.ncmd=Bin.data_read(Bin.Num_start+9)*256+Bin.data_read(Bin.Num_start+8); % номер сообщения (о чем сообщение)
        
        for(k=1:Bin.Num_posts) %определение типа сообщения (его номер)
            switch(Bin.ncmd(k)) 
                case hex2dec('20')
                    if(LatLonData.start==0) %обрабатываем самые ранние данные
                        LatLonData.start=Bin.Num_start(k);% начало сообщения 0х20
                    end
                case hex2dec('10')
                    if(phData.start==0) % т.е. те данные, которые приняты полностью
                        phData.start=Bin.Num_start(k);% начало сообщения 0х10    
                    end
            end
        end
        
        
        while(settings.LatLonData==1) %обработка сообщения 0х20
            if((LatLonData.start>0)&(LatLonData.start<length(Bin.data_read)-256))
                fprintf('\n ____________0x20___________ \n')
                tmp=nan;
                for(k=1:8) %UTC
                    tmp(k)=Bin.data_read(LatLonData.start+11+k);
                end
                LatLonData.UTC=bin2num(tmp,'double');
                fprintf('UTC (c 01.01.2008): %9.0f sec \n', LatLonData.UTC)
                %
                %Lat and Lon
                for(k=1:8) %Lat
                    tmp(k)=Bin.data_read(LatLonData.start+19+k);
                end
                LatLonData.Lat=bin2num(tmp,'double')*180/pi;
                fprintf('Lat: %f \n', LatLonData.Lat)
                
                for(k=1:8) %Lon
                    tmp(k)=Bin.data_read(LatLonData.start+27+k);
                end
                LatLonData.Lon=bin2num(tmp,'double')*180/pi;
                fprintf('Lon: %f \n', LatLonData.Lon)
                plot(LatLonData.Lon,LatLonData.Lat,'.b','MarkerSize',15)
                plot_google_map
            end
            break;
        end
        
        while(settings.phData==1) %обработка сообщения 0х10
            if((phData.start>0)&(phData.start<length(Bin.data_read)-256))
                fprintf('\n ____________0x10___________ \n')
                %UTC
                phData.UTC=bin2num(Bin.data_read(phData.start+12:phData.start+20),'double');
                fprintf('UTC (c 01.01.2008): %9.0f sec \n', phData.UTC) %print UTC
                
                if(StartTime<0) %задаём начальное время (для графиков)
                    StartTime=phData.UTC;
                end
                
                %колличество КА, по которым передается измерительная информация
                phData.NumKA=bin2num(Bin.data_read(phData.start+24:phData.start+28),'int');
                fprintf('NUM KA: %d  \n', phData.NumKA) %print число КА в решение
                
                %обработка данных с путника
                for(k=1:phData.chisl_spytnicov) %переписываем данные для нового такта
                    for(m=1:phData.NumPointPlot-1)
                        phData.phase(phData.NumPointPlot-m+1,k)=phData.phase(phData.NumPointPlot-m,k);
                        phData.SignalToNoise(phData.NumPointPlot-m+1,k)=phData.SignalToNoise(phData.NumPointPlot-m,k);
                        phData.reliable(phData.NumPointPlot-m+1,k)=phData.reliable(phData.NumPointPlot-m,k);
                    end
                end
                
                for(k=1:phData.NumPointPlot-1) %переписываем для нового такта время
                    phData.time(phData.NumPointPlot-k+1)=phData.time(phData.NumPointPlot-k);
                end
                
                phData.reliable(1,1:phData.chisl_spytnicov)=nan; %обработка данных с "к"-го спутника
                phData.SignalToNoise(1,1:phData.chisl_spytnicov)=nan;
                phData.phase(1,1:phData.chisl_spytnicov)=nan;
                phData.time(1)=phData.UTC-StartTime;
                for(k=1:phData.NumKA)%обработка данных с "к"-го спутника
                    [phData.tmp_KAnumber, phData.tmp_reliable, phData.tmp_SignalToNoise,...
                        phData.tmp_phase]=NaviBinV3_x10(...
                        Bin.data_read(phData.start+12+56*k-40:phData.start+12+56*k+15));
                phData.reliable(1,phData.tmp_KAnumber)=phData.tmp_reliable;
                phData.SignalToNoise(1,phData.tmp_KAnumber)=phData.tmp_SignalToNoise;
                phData.phase(1,phData.tmp_KAnumber)=phData.tmp_phase;
                end
                
            end
        break;    
        end
    end
end


[logik,ind]=min(sum(isnan(phData.phase)));

for(k=1:length(ind))
    figure
    plot(phData.time,phData.phase(:,ind(k)));
end