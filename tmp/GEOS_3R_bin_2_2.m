clear
clc

%fclose(instrfind)
%настройки COM порта
Num_com_port='COM25';
baud=115200;
com_port=serial(Num_com_port, 'BaudRate', baud);

%что обрабатывать
settings.LatLonData=0; %сообщение 0х20. Ѕазовый набор географических координат
settings.phData=1;     %сообщение 0х10.
phData.NumPointPlot=50; % максимальное число точек на графике
phData.NumPointPoiskKA=4;    % число точек дл€ поиска нужного  ј
phData.chisl_spytnicov=130;% условно, с запасов - число спутников 

phData.reliable(1:phData.NumPointPlot,1:phData.chisl_spytnicov)=nan; 
phData.SignalToNoise(1:phData.NumPointPoiskKA,1:phData.chisl_spytnicov)=nan;
phData.phase(1:phData.NumPointPlot,1)=nan;
phData.time(1:phData.NumPointPlot,1)=nan;

Bin.preamble=[hex2dec('47'); hex2dec('45'); hex2dec('4f'); hex2dec('53'); ...
    hex2dec('72'); hex2dec('33'); hex2dec('50'); hex2dec('53')]; %преамбула GEOSr3PS

%настройки бинарного протокола приемника
% выдача сообщений 0х10
Bin.data_write(1:8)=Bin.preamble(1:8);
Bin.data_write(9:16)=[hex2dec('4F'), 0, 1, 0, 0, 0, hex2dec('01'), 0];
BinDataWrite(Bin.data_write, com_port);

% темп выдачи (10 √ц)
Bin.data_write(1:8)=Bin.preamble(1:8);
Bin.data_write(9:16)=[hex2dec('44'), 0, 1, 0, 0, 0, 0, 0];
BinDataWrite(Bin.data_write, com_port);

StartTime=-1; % врем€ начала работы

while(1==1) % определ€ем номер  ј
    for(cikl_for=1:phData.NumPointPoiskKA)
        %считывание даннных из порта
        fopen(com_port);
        Bin.data_read=fread(com_port,512);
        Bin.data_read(end+1:1024)=fread(com_port,512);
        Bin.data_read(end+1:1536)=fread(com_port,512);
        Bin.data_read(end+1:2048)=fread(com_port,512);
        Bin.data_read(end+1:2560)=fread(com_port,512);
        Bin.data_read(end+1:3072)=fread(com_port,512);
        fclose(com_port);

        LatLonData.start=0;
        phData.start=0;

        Bin.Num_posts=0;% колличество полученных сообщений
        for(k=1:(length(Bin.data_read)-10)) % цикл поиска начала сообщени€ и их колличества
           logik_Matrix(1:8)=(Bin.data_read(k:k+7)==Bin.preamble(1:8));
           logik=logik_Matrix(1);
           for (ind=2:8)
                logik=logik&logik_Matrix(ind); 
           end

           if(logik)
               Bin.Num_posts=Bin.Num_posts+1; %инкремент колличства сообщений
               Bin.Num_start(Bin.Num_posts)=k;% €чейка начала сообщени€
           end
        end

        if (Bin.Num_posts>0) % если сообщени€ получены из приемника
            Bin.datN=Bin.data_read(Bin.Num_start+11)*256+Bin.data_read(Bin.Num_start+10); %количество слов в сообщение 
            Bin.ncmd=Bin.data_read(Bin.Num_start+9)*256+Bin.data_read(Bin.Num_start+8); % номер сообщени€ (о чем сообщение)

            for(k=1:Bin.Num_posts) %определение типа сообщени€ (его номер)
                switch(Bin.ncmd(k)) 
                    case hex2dec('20')
                        if(LatLonData.start==0) %обрабатываем самые ранние данные
                            LatLonData.start=Bin.Num_start(k);% начало сообщени€ 0х20
                        end
                    case hex2dec('10')
                        if(phData.start==0) % т.е. те данные, которые прин€ты полностью
                            phData.start=Bin.Num_start(k);% начало сообщени€ 0х10    
                        end
                end
            end
            
            while(1==1)% выбор спутника. критерий- макс. с/ш
                if((phData.start>0)&(phData.start<length(Bin.data_read)-256))
                    phData.NumKA=bin2num(Bin.data_read(phData.start+24:phData.start+28),'int');
                    fprintf('NUM KA: %d  \n', phData.NumKA) %print число  ј в решение
                    for(k=1:phData.NumKA)%обработка данных с "к"-го спутника
                        [phData.tmp_KAnumber, phData.tmp_reliable, phData.tmp_SignalToNoise,...
                            phData.tmp_phase]=NaviBinV3_x10(...
                            Bin.data_read(phData.start+12+56*k-40:phData.start+12+56*k+15));
                        phData.SignalToNoise(cikl_for,phData.tmp_KAnumber)=phData.tmp_SignalToNoise;
                    end
                end
                break
            end
        end
    end
    %услови€ выхода из цикла выбора  ј
   [logik,ind_KA]=max(sum(phData.SignalToNoise));%поиск максимального отношени€ с/ш
   if(logik>30*phData.NumPointPoiskKA)
       fprintf('\n ok \n num KA= %d \n max signalTOnoise %f \n', ind_KA, logik/phData.NumPointPoiskKA)
       break
   else
       fprintf('\n not \n max signalTOnoise= %f \n', logik/phData.NumPointPoiskKA)
   end
end

%закончили поиск
phData.SignalToNoise(1:phData.NumPointPlot,1:phData.chisl_spytnicov)=nan;

while(1==1) % обработка данных с заданного  ј

    Bin.data_poisk(1:8,1)=0;
    Bin.data_read=nan;
    Bin.datN=0;
    Bin.ncmd=0;
    fopen(com_port);
    while(1==1)
        Bin.data_poisk(1:7,1)=Bin.data_poisk(2:8);
        Bin.data_poisk(8,1)=fread(com_port,1);
        if(Bin.data_poisk(1:8)==Bin.preamble(1:8))
            Bin.ncmd=fread(com_port,1); % номер сообщени€ (о чем сообщение)
            Bin.ncmd=fread(com_port,1)*256+Bin.ncmd;
            Bin.datN=fread(com_port,1); %количество слов в сообщение
            Bin.datN=fread(com_port,1)*256+Bin.datN;
            if(Bin.ncmd==16)%16==0x10
                for(k=1:Bin.datN)
                    Bin.data_read(4*(k-1)+1:4*k,1)=fread(com_port,4);
                end
                break
            end
        end
    end
    fclose(com_port);
        
    phData.start=-11;

    while(1==1) %обработка сообщени€ 0х10
            fprintf('\n ____________0x10___________ \n')
            %UTC
            phData.UTC=bin2num(Bin.data_read(phData.start+12:phData.start+20),'double');
            fprintf('UTC (c 01.01.2008): %9.0f sec \n', phData.UTC) %print UTC
            
            
            %колличество  ј, по которым передаетс€ измерительна€ информаци€
            phData.NumKA=bin2num(Bin.data_read(phData.start+24:phData.start+28),'int');
            fprintf('NUM KA: %d  \n', phData.NumKA) %print число  ј в решение
            
            for(m=1:phData.NumPointPlot-1)% смещаемс€ на такт вниз
                phData.phase(phData.NumPointPlot-m+1,1)=phData.phase(phData.NumPointPlot-m,1);
                phData.SignalToNoise(phData.NumPointPlot-m+1,1)=phData.SignalToNoise(phData.NumPointPlot-m,1);
                phData.reliable(phData.NumPointPlot-m+1,1)=phData.reliable(phData.NumPointPlot-m,1);
                phData.time(phData.NumPointPlot-m+1,1)=phData.time(phData.NumPointPlot-m,1);
            end
            
            if(StartTime<0) %задаЄм начальное врем€ (дл€ графиков)
                StartTime=phData.UTC;
            end
            
            phData.time(1,1)=phData.UTC-StartTime;
            
            for(k=1:phData.NumKA)%обработка данных с "к"-го спутника
                [phData.tmp_KAnumber, phData.tmp_reliable, phData.tmp_SignalToNoise,...
                    phData.tmp_phase]=NaviBinV3_x10(...
                    Bin.data_read(phData.start+12+56*k-40:phData.start+12+56*k+15));
                if(phData.tmp_KAnumber==ind_KA)
                    logik=1;
                    phData.reliable(1,1)=phData.tmp_reliable;
                    phData.SignalToNoise(1,1)=phData.tmp_SignalToNoise;
                    phData.phase(1,1)=phData.tmp_phase;
                    break
                end
                if(logik==0)
                    phData.reliable(1,1)=nan;
                    phData.SignalToNoise(1,1)=nan;
                    phData.phase(1,1)=nan;
                else
                    logik=0;
                end
                
            end
        break;
    end

    
    %обработка данных:
    if(sum(~isnan(phData.phase))>2)
        k=find(isnan(phData.phase)==0);
        apr.phase=phData.phase(k);
        apr.time=phData.time(k);
        apr.p2=polyfit(apr.time,apr.phase,2);
        apr.DataFit = polyval(apr.p2,apr.time);
        apr.DataPhase2=apr.phase-apr.DataFit;
        apr.aprTime=min(apr.time):(max(apr.time)-min(apr.time))/(phData.NumPointPlot*20):max(apr.time);
        if(length(apr.time)>fix(phData.NumPointPlot/10))
            apr.aprP2=polyfit(apr.time,apr.DataPhase2,fix(phData.NumPointPlot/10));
            apr.aprDataPhase2=polyval(apr.aprP2,apr.aprTime);
        else
            apr.aprTime=nan;
            apr.aprDataPhase2=nan;
        end
    else
        apr.DataPhase2=nan;
        apr.DataFit=nan;
        apr.time=nan;
        apr.aprTime=nan;
        apr.aprDataPhase2=nan;
    end
%     
    
    %вывод графиков:   
    subplot(2,2,1)
    plot(phData.time,phData.phase, 'b', apr.time,apr.DataFit, 'r')
    xlabel('time, sec');
    ylabel('phase, cycles');
    subplot(2,2,2)
    plot(phData.time,phData.SignalToNoise)
    xlabel('time, sec');
    ylabel('signal to noise, dBHz');
    subplot(2,2,3)
    plot(apr.time,apr.DataPhase2)
    xlabel('time, sec');
    ylabel('d phase, cycles');
    subplot(2,2,4)
    plot(apr.aprTime,apr.aprDataPhase2)
    xlabel('time, sec');
    ylabel('d phase, cycles');
    drawnow
    
end
    
        
        
        
       
    


