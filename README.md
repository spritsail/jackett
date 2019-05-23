[hub]: https://hub.docker.com/r/spritsail/jackett
[git]: https://github.com/spritsail/jackett
[drone]: https://drone.spritsail.io/spritsail/jackett
[mbdg]: https://microbadger.com/images/spritsail/jackett

# [spritsail/Jackett][hub]

[![](https://images.microbadger.com/badges/image/spritsail/jackett.svg)][mbdg]
[![Latest Version](https://images.microbadger.com/badges/version/spritsail/jackett.svg)][hub]
[![Git Commit](https://images.microbadger.com/badges/commit/spritsail/jackett.svg)][git]
[![Docker Pulls](https://img.shields.io/docker/pulls/spritsail/jackett.svg)][hub]
[![Docker Stars](https://img.shields.io/docker/stars/spritsail/jackett.svg)][hub]
[![Build Status](https://drone.spritsail.io/api/badges/spritsail/jackett/status.svg)][drone]


[Jackett](https://github.com/Jackett/Jackett) dotnet build, running in Alpine Linux, with only the bare essentials required to run.

**This is an experimental dotnet build of Jackett. Proceed with caution**

### Usage

```bash
docker run -dt
    --name=jackett
    --restart=always
    -v $PWD/config:/config
    -p 9117:9117
    spritsail/jackett
```

### Volumes

* `/config` - Jackett configuration file and database storage. Should be readable and writeable by `$SUID` 

`$SUID` defaults to 912

