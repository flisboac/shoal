

## Phases

```

[rcinit] -----> [cmd] -----> [dist] -----> [setup] -----> [config] -----> [build] -----> [run]
+-> version     +-> help     +-> dist      +-> setup      +-> configure   +-> build      +-> pack|save
                +-> info     +-> clean                                                   +-> run
                             +-> distclean                                               +-> start
                             +-> imgclean                                                +-> stop
                                                                                         +-> push
                                                                                         +-> deploy

* Goals are listed below the phases they're mapped into
* Config cache files are generated first at the end of the setup phase,
  and may be updated up to the end of the config phase.
* Build cache files are generated at the build phase.
* Runtime cache files are generated at the run phase.
  Each goal/plugin may have its own runtime cache group (of files).

```
