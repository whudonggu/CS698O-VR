FROM nvidia/cuda:8.0-cudnn6-devel-ubuntu16.04 

RUN echo "deb http://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1604/x86_64 /" > /etc/apt/sources.list.d/nvidia-ml.list

RUN apt-get update && apt-get install -y --no-install-recommends \
         build-essential \
         cmake \
         git \
         curl \
         vim \
         ca-certificates \
         libjpeg-dev \
         libpng-dev &&\
     rm -rf /var/lib/apt/lists/*

RUN curl -o ~/miniconda.sh -O  https://repo.continuum.io/miniconda/Miniconda2-latest-Linux-x86_64.sh  && \
     chmod +x ~/miniconda.sh && \
     ~/miniconda.sh -b -p /opt/conda && \     
     rm ~/miniconda.sh && \
     /opt/conda/bin/conda install conda-build && \
     /opt/conda/bin/conda create -y --name pytorch-py27 python=2.7 numpy pyyaml scipy ipython mkl&& \
     /opt/conda/bin/conda clean -ya 
ENV PATH /opt/conda/envs/pytorch-py27/bin:$PATH
RUN conda install --name pytorch-py27 -c soumith magma-cuda80
# This should be done before pip so that requirements.txt is available
WORKDIR /opt/pytorch
COPY pytorch/ .

RUN TORCH_CUDA_ARCH_LIST="3.5 5.0 5.2 6.0 6.1+PTX" TORCH_NVCC_FLAGS="-Xfatbin -compress-all" \
    CMAKE_PREFIX_PATH="$(dirname $(which conda))/../" \
    pip install -v .

RUN git clone https://github.com/pytorch/vision.git && cd vision && pip install -v .

# Additional commands follow
RUN apt-get update && apt-get install -y zsh
RUN git clone git://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh && \
    cp ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc && \
    chsh -s /bin/zsh
#RUN sed -i -e 's/robbyrussell/avit/g' ~/.zshrc

RUN pip install jupyter matplotlib

# Add a notebook profile. 
RUN mkdir -p -m 700 /root/.jupyter/ && \ 
	echo "c.NotebookApp.ip = '*'\nc.NotebookApp.open_browser = False\nc.NotebookApp.password = u'sha1:e94bb1861d4e:0046602b5a1abfea909c54e1615dfda5d4dae851'\nc.NotebookApp.allow_root = True" >> /root/.jupyter/jupyter_notebook_config.py

# Some pretrained nn models for assignment 1
RUN mkdir -p /root/.torch/models
ADD https://download.pytorch.org/models/vgg16-397923af.pth https://download.pytorch.org/models/resnet18-5c106cde.pth /root/.torch/models/

EXPOSE 8888

RUN mkdir /root/Project
WORKDIR /root/Project
RUN chmod -R a+w /root/Project

ENTRYPOINT ["/bin/zsh"]
