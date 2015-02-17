[m,n]=size(d.counts);
C=log(d.counts+1);
iod=sum(C')+n^2*(sum((C.^(-1))')).^(-1);iod=iod';%Selby's Wald statistic for the index of dispersion
d.iod=iod;
cr=chi2inv(.99,n-1);%critical point to evaluate non-central chi2, to compute power of W, see Selby '65
iod_fdr=1-ncx2cdf(cr,n-1,iod,'upper');%false discovery rate of a test of the null hypothesis of no
                            %differential gene expression between cells, at
                            %the 1% significance level
d.iod_fdr=iod_fdr;
numnz=sum(d.counts'>0)';%number of cells with non-zero read counts, genewise
num0=n-numnz;
d.pnz=numnz/n;%percent of cells with non-zero read counts, genewise
%method of Selby, test for zero inflation with poisson null hypothesis
%lmbda=poissfit(d.counts')';%fit poisson distribution, under the null hypothesis of no zero inflation
%p0=poisspdf(0,lmbda);
%zinf_stat=((num0-n*p0).^2)./(n*p0.*(1-p0)-n*mean(C')'.*p0.^2);
%d.zinf_stat=zinf_stat;
%d.zinfp=chi2cdf(zinf_stat,1,'upper');%score test for more zeros than expected under a Poisson model

%method of Yang et al, test zero inflation with generalized poisson null
lmbda=zeros(m,1);%mean of generalized poisson
options=optimoptions('fminunc','Algorithm','quasi-newton','Display','off','TolFun',1e-3);
parfor i=1:m
    y=d.counts(i,:);yb=mean(y);
    if nnz(y)==0
        zinf_stat(i)=Inf;
        continue;
    end
    [lmbda(i),fval]=fminunc(@(x) abs(sum(y.*(y-1)./(x*(yb-y)+yb*y))-n),mean(y),options);
    zinf_stat(i)=(num0(i)*exp(lmbda(i))-n)^2/(n*exp(lmbda(i))-n-n*lmbda(i)*(lmbda(i)+2)/2);
end
d.zinfp=chi2cdf(zinf_stat,1,'upper');%score test for more zeros than expected under a Poisson model
d.zinfp(d.pnz==1)=1;
d.zinfp(d.pnz==0)=0;
%%
[~,q]=mafdr(d.zinfp);%control for false discovery
d.zinf_fdr=q;
d.zinf_fdr(d.pnz==0)=0;
f=figure;
bet1=0.01;bet2=0.01;
idx_pnz=find(d.zinf_fdr<bet2);
idx_pnzc=find(d.zinf_fdr>=bet2);
idx_iod=find(d.iod_fdr<bet1);
idx_iodc=find(d.iod_fdr>=bet1);
gidx={};
idx1=find(2*d.iod_fdr<bet1&2*d.zinf_fdr>=bet2);
idx2=find(2*d.iod_fdr>=bet1|2*d.zinf_fdr<bet2);
%idx1=find(d.iod_fdr<=bet1);idx2=find(d.iod_fdr>bet1);
gidx(idx1)={'good'};
%gidx(intersect(idx_pnzc,idx_iodc))={'2'};
%gidx(intersect(idx_pnz,idx_iodc))={'3'};
%gidx(intersect(idx_pnzc,idx_iod))={'4'};
gidx(idx2)={'bad'};
gscatter(d.pnz,log(d.iod)/max(log(d.iod)),gidx','br','o',6);
axis square
%set(gca,'XLim',[0 1],'Ylim',[0,1]);