# MRO-RStudio

Construct a Docker image featuring the
[RStudio Server](https://www.rstudio.com/products/rstudio/) IDE running atop
the [Microsoft R Open (MRO)](https://mran.microsoft.com/open) distribution of R.
The Dockerfile is heavily based on the
[rocker/rstudio](https://hub.docker.com/r/rocker/rstudio) image except that the
rocker image is based on Debian (rather than Ubuntu 18.04) and the rocker
image tracks the official [GNU/R](https://www.r-project.org) distribution.

## Quickstart

To use the image, run:

```bash
docker run -d --rm -p 8787:8787 -e PASSWORD=your_password blueogive/mro-rstudio
```

and browse to [http://127.0.0.1:8787](http://127.0.0.1:8787) or, equivalently,
[http://localhost:8787](http://localhost:8787) on the host where
the container is running. When presented with the RStudio login screen,
enter username as `docker` and password as `your_password`.

To mount the working directory as a volume within the container:

```bash
docker run -d --rm -p 8787:8787 -v $(pwd):/home/docker/work -e PASSWORD=your_password blueogive/mro-rstudio
```

## Adding a Shiny Server

As with the [rocker/rstudio](https://hub.docker.com/r/rocker/rstudio) image,
you can elect to install and start a
[Shiny Server](https://www.rstudio.com/products/shiny/) when you instantiate
the container. To do so, start the container with this command:

```bash
docker run -d --rm -p 8787:8787 -e ADD=shiny -e PASSWORD=your_password blueogive/mro-rstudio
```
