# aidreaming

This will pull down the Fooocus github repository, download models, slightly modify the repo and build a docker container.

## Requirements

- `Docker`
- Ability to run this script in a linux system (WSL also works provided you have Docker integration)

## Building Images

### AIDreaming

0. Update the versions of stuff as required

    - [ComfyUI](https://github.com/comfyanonymous/ComfyUI) can be provided as a build arg in the docker build command, or update the dockerfile itself
    - [Fooocus](https://github.com/lllyasviel/Fooocus.git) update the bash variable in build.sh

1. Build the images

    ```sh
    bash build.sh
    ```

TODO: Fooocus work could be done entirely in a docker stage, removing any additional traces from the build system

### Reaper

```sh
# assumes user is not in the docker group
# assumes you're in the directory of the README
sudo docker build --pull --no-cache -f reaper.Dockerfile .
```
