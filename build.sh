#!/bin/bash

# location for Fooocus repo to be installed to for ease of use
REPOS_DIR=~/repos

# working commit for Fooocus
FOOOCUS_COMMIT="09e0d1cb3ae5a1d74443009a41da9f96c1b54683"

# make repos dir if it doesn't already exist
if [ ! -d "$REPOS_DIR" ]; then
    mkdir -p "$REPOS_DIR"
fi

# check git is installed
if git --version >/dev/null 2>&1; then
    echo "Git is installed, proceding."
else
    echo "Git is not installed"
    echo "This script will now install git"
    sudo apt-get update
    sudo DEBIAN_FRONTEND=noninteractive apt-get install git -y
fi

if [ ! -d "$REPOS_DIR/Fooocus" ]; then
    echo "Fooocus not present. Performing a pull to ensure we've got everything"
    git clone https://github.com/lllyasviel/Fooocus.git $REPOS_DIR/Fooocus
else
    echo "Fooocus already present. Performing a fetch to checkout newer commits as required"
    git -C $REPOS_DIR/Fooocus fetch --all
fi

# Pin Fooocus to known working for everything
# TODO: silence the detached head state msg ?
git -C $REPOS_DIR/Fooocus checkout $FOOOCUS_COMMIT

# place Dockerfile and requirements to Fooocus directory and begin building the container state
# will always overwrite what is present
cp $(pwd)/aidreaming.dockerfile $REPOS_DIR/Fooocus/
cp $(pwd)/requirements_aidreaming.txt $REPOS_DIR/Fooocus/

echo ""
echo "If you have already downloaded the models separately You will need to interrupt"
echo "this build process and place them in the right location within the git repo."
sleep 2
echo "The contents of this script contains the directories for the models."
sleep 2
echo "Once this is done restart the script and type anything other than 'exit' at the following prompt."
echo ""

sleep 5

read -p "Do you want to download the models? (Type 'yes' to download now (checks if file exists first), 'exit' to interrupt this process): " confirmation
if [ "$confirmation" = "yes" ]; then
    # Downloading models only if they are not already downloaded
    base_model='https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0_0.9vae.safetensors'
    if [ -f $REPOS_DIR/Fooocus/models/checkpoints/sd_xl_base_1.0_0.9vae.safetensors ]; then
        echo "Base model already exists"
    else    
        echo "Base model does not exist."
        echo "Downloading to $REPOS_DIR/Foocus/models/checkpoints"
        wget -P $REPOS_DIR/Fooocus/models/checkpoints $base_model
    fi

    refiner_model='https://huggingface.co/stabilityai/stable-diffusion-xl-refiner-1.0/resolve/main/sd_xl_refiner_1.0_0.9vae.safetensors'
    if [ -f $REPOS_DIR/Fooocus/models/checkpoints/sd_xl_refiner_1.0_0.9vae.safetensors ]; then
        echo "refiner model already exists"
    else
        echo "refiner model does not exist."
        echo "Downloading to $REPOS_DIR/Foocus/models/checkpoints"
        wget -P $REPOS_DIR/Fooocus/models/checkpoints $refiner_model
    fi

    lora_model='https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_offset_example-lora_1.0.safetensors'
    if [ -f $REPOS_DIR/Fooocus/models/loras/sd_xl_offset_example-lora_1.0.safetensors ]; then
        echo "Lora model already exists"
    else
        echo "Lora model does not exist."
        echo "Downloading to $REPOS_DIR/Foocus/models/loras"
        wget -P $REPOS_DIR/Fooocus/models/loras $lora_model
    fi
elif [ "$confirmation" = "exit" ]; then
    echo "Process interrupted. Exiting the script."
    exit 0
else
    echo "Confirmation not received. Skipping the download. This prevent the models being built into the docker image."
    sleep 5
fi

# Change the default number of images to generate per prompt to 1
sed -i "s/image_number = gr.Slider(label='Image Number', minimum=1, maximum=32, step=1, value=2)/image_number = gr.Slider(label='Image Number', minimum=1, maximum=32, step=1, value=1)/" $REPOS_DIR/Fooocus/webui.py

# Stop the launch script trying to download models
sed -i "s/^download_models()/#download_models()/" $REPOS_DIR/Fooocus/launch.py

# enable cuda_malloc() function
sed -i "s/# cuda_malloc()/cuda_malloc()/" $REPOS_DIR/Fooocus/launch.py

# build container
echo "Building the docker image"
sleep 1
sudo docker build --pull --no-cache -f $REPOS_DIR/Fooocus/aidreaming.dockerfile -t aidreaming:0.0.1 $REPOS_DIR/Fooocus

echo ""
echo "You can now run the container with"
echo "docker run --gpus all -p 7860:7860 aidreaming:0.0.1"
echo ""
echo "This does not work in --detached mode."
echo "if you want to volume mount the models into  container use -v $(pwd)/localmodel:/app/models/checkpoints"
