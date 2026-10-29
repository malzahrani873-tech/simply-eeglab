// Components available inside lesson MDX without imports.
import MenuPath from './MenuPath.astro';
import UiLabel from './UiLabel.astro';
import En from './En.astro';
import Callout from './Callout.astro';
import Figure from './Figure.astro';
import ImageSpec from './ImageSpec.astro';
import Methods from './Methods.astro';
import BeforeAfter from './BeforeAfter.astro';
import YouTube from './YouTube.astro';
import LessonComplete from './LessonComplete.astro';
import IcaGameTeaser from './IcaGameTeaser.astro';
import FilterDemo from '../interactive/FilterDemo.astro';
import RerefDemo from '../interactive/RerefDemo.astro';
import EpochRejectDemo from '../interactive/EpochRejectDemo.astro';

export const components = {
  MenuPath, UiLabel, En, Callout, Figure, ImageSpec, Methods, BeforeAfter, YouTube, LessonComplete, IcaGameTeaser,
  FilterDemo, RerefDemo, EpochRejectDemo,
};
