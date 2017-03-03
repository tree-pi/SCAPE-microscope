% load data

close all
datap = '/Users/zhiwei/Google Drive/Schoppik Rotation/Data/IZ SC fish2 runA 01-05-17/';
load CorpImg
for nslice = 1:2:11
    picArr = nslice:25:1000;
    ntr = 40*(3/4); % split into 2 groups
    temp = randperm(40);
    trSet = temp(1:ntr);
    valSet = temp(ntr+1:end);
    
    dims = range(CorpRange)+1; % number of pix for each dimension
    nd1=dims(1);
    nd2=dims(2);
    thres = 150; % 1.5 is randomly decided; only above this threshold is considered a pixel with signal
    
    
    meantrIm = zeros(range(CorpRange)+1,'uint16');
    for ipic = trSet
        meantrIm = meantrIm+allcorpim{ipic};
    end
    meantrIm = meantrIm/length(trSet); % in total 40 images for each slice(i.e. each z)
    
    meanvalIm = zeros(range(CorpRange)+1,'uint16');
    for ipic = valSet
        meanvalIm = meanvalIm+allcorpim{ipic};
    end
    meanvalIm = meanvalIm/length(valSet); % in total 40 images for each slice(i.e. each z)
    
    PosMtrTr =img2signpos(meantrIm,thres);
    PosMtrVal =img2signpos(meanvalIm,thres);
    
    %% pic preprocessing finished. now start clustering
    plotpic= 0;
    plotcluster=0;
    plotsumd=1;
    
    Cbest= NaN;
    allsumd =[];
    allC=cell(0);
    NnArr = 5:25;
    idxbest=0;
    
    % exclusion criteria: manually set by looking into images
    distfar = 100;
    distmerge = 10;
    
    for Nn=25 % NnArr % tobedone: delete NnArr if it's fixed for all subs
        sumdbest = 1e6;
        % first, training w/ k-means
        for irun = 1:2 %0 % bc there's randomness in kmeans
            [idx,C,sumd] = kmeans(PosMtrTr,Nn);
            if mean(sumd)<sumdbest
                Cbest=C;
                sumdbest=sumd;
                idxbest=idx;
            end
        end
        % apply exclusion/merging criteria
        % get an idea of dim: how small is too small? too little? too
        % close?
        cnn = NaN(Nn,1);
        Cdist = NaN(Nn);
        for ic = 1:Nn
            Cdist(ic,:) = sqrt(sum((repmat(Cbest(ic,:),Nn,1)-Cbest).^2,2));
            cnn(ic) = sum(idx==ic);
        end
        % then, compare with the figures of clusters
        tooclose = 7; %any 2 clusters less than 7 may be too close
        toosmall = 9;% any clusters with square range less than this is too small -- hwever, this dep on threshold?
        % exclusion1: clusters too close to each other => merge.

        % exclusion2: too small cluster with too little cells = >exclude

    
    % second, cross-valid on validation set: just by eye!
    alldist = NaN(size(PosMtrVal,1),Nn);
    for ic = 1:Nn
        alldist(:,ic) = sum((PosMtrVal-Cbest(ic,:)).^2,2); % geometric dist
    end
    allsumd= [allsumd;sum(min(alldist,[],2))];
    allC = {allC,Cbest};
    %%
    if plotpic==1
        figure()
        plot(PosMtrTr(:,2),PosMtrTr(:,1),'w.')
        hold on
        plot(Cbest(:,2),Cbest(:,1),'ro','MarkerFaceColor','r','MarkerSize',4)
        title(sprintf('%d clusters',Nn))
        set(gca,'Color',[0 0 0]);
        axis equal
        ylim([0,range(CorpRange(:,1))+1])
        xlim([0,range(CorpRange(:,2))+1])
    end
end
[minSumd,bestNn] = min(allsumd);
bestNn = bestNn+NnArr(1)-1

% final clustering: combine pixels in both training & validation set, i.e.
% take the mean for all img; then assign clusters for each pxl.
meanIm=zeros(size(meantrIm));
for ipic= picArr
    meanIm = meanIm+allcorpim{ipic};
end


if plotsumd==1
    figure
    plot(NnArr,-(allsumd),'+')
    hold on
    plot(bestNn,-minSumd,'ro')
    title(sprintf('pic %d',ipic))
end

%% result figure: overlay clustering results on initial image
if plotcluster==1
    h1=figure;
    subplot 311
    imshow(meantrIm,[90,450]);
    %plot(Cbest(:,2),Cbest(:,1),'ro','MarkerFaceColor','r','MarkerSize',4)
    subplot 312
    imshow(meantrIm,[90,450]);
    hold on
    for icl = 1:size(Cbest,1)
        thiscl=idxbest==icl;
        plot(PosMtrTr(thiscl,2),PosMtrTr(thiscl,1),'.','Color',rand(1,3))
        text(mean(PosMtrTr(thiscl,2)),mean(PosMtrTr(thiscl,1)),num2str(icl),'Color','w')
        hold on
    end
    subplot 313
    imshow(meantrIm,[90,450]);
    hold on
    plot(Cbest(:,2),Cbest(:,1),'ro','MarkerFaceColor','r','MarkerSize',3)
    
    saveas(h1,sprintf('kmean_clust/slice_%d_clstrTr.png',picArr(1)))
    
    
end

end

function PosMtr = img2signpos(img, thres)
SignArrTr = img>thres;
ImFilt = img;
ImFilt(SignArrTr) = 1;
ImFilt(~SignArrTr) = 0;
temp = 1:numel(ImFilt);
indSig = temp(ImFilt>0)';
PosMtr = [mod(indSig,size(img,1)),ceil(indSig/size(img,1))]; % each row is coordinates for a signal pixel(i.e. a data point);
% check the filtering method
%{
figure;subplot 311;imshow(meanIm,[90,450]);
subplot 312;imshow(ImFilt,[0,1.1]); title('filtered image')
subplot 313;plot(PosMtr(:,2),max(PosMtr(:,1))-PosMtr(:,1),'k.');title('check position index')
%}
end