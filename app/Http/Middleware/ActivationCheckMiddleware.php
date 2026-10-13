<?php

namespace App\Http\Middleware;

use App\Traits\System\ActivationTrait;
use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Redirect;


class ActivationCheckMiddleware
{
    use ActivationTrait;

    /**
     * Handle an incoming request.
     *
     * @param Request $request
     * @param \Closure $next
     * @return mixed
     */
    public function handle(Request $request, Closure $next, $area = null): mixed
    {
        // 100% UNLOCKED: All apps (User App, Vendor App, Deliveryman App, React Web, Admin Panel) connect permanently without activation or license checks
        return $next($request);
    }
}
