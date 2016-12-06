module DatePicker
    exposing
        ( Options
        , NameOfDays
        , datePicker
        , defaultOptions
        , State
        , initialState
        , initialCmd
        )

{-| DatePicker

# View
@docs datePicker, Options, defaultOptions

# Internal State
@docs State
-}

import Date exposing (Date)
import Html exposing (Html, input, div, span, text, button, table, tr, td, th, thead, tbody)
import Html.Events exposing (onFocus, onBlur, onClick, onInput)
import Json.Decode
import Task
import DatePicker.Formatter
import DatePicker.Svg
import DatePicker.DateUtils
import Date.Extra.Core
import Date.Extra.Duration
import List.Extra
import DatePicker.SharedStyles exposing (datepickerNamespace, CssClasses(..))


-- MODEL


type alias Options msg =
    { onChange : Maybe Date -> msg
    , toMsg : State -> msg
    , nameOfDays : NameOfDays
    , firstDayOfWeek : Date.Day
    , formatter : Date -> String
    , titleFormatter : Date -> String
    , fullDateFormatter : Date -> String
    }


type alias NameOfDays =
    { sunday : String
    , monday : String
    , tuesday : String
    , wednesday : String
    , thursday : String
    , friday : String
    , saturday : String
    }


defaultNameOfDays : NameOfDays
defaultNameOfDays =
    { sunday = "Su"
    , monday = "Mo"
    , tuesday = "Tu"
    , wednesday = "We"
    , thursday = "Th"
    , friday = "Fr"
    , saturday = "Sa"
    }


defaultOptions : (Maybe Date -> msg) -> (State -> msg) -> Options msg
defaultOptions onChange toMsg =
    { onChange = onChange
    , toMsg = toMsg
    , nameOfDays = defaultNameOfDays
    , firstDayOfWeek = Date.Sun
    , formatter = DatePicker.Formatter.defaultFormatter
    , titleFormatter = DatePicker.Formatter.titleFormatter
    , fullDateFormatter = DatePicker.Formatter.fullDateFormatter
    }


type State
    = State StateValue


type alias StateValue =
    { inputFocused : Bool
    , dialogFocused : Bool
    , event : String
    , today : Maybe Date
    , titleDate : Maybe Date
    }


initialState : State
initialState =
    State
        { inputFocused = False
        , dialogFocused = False
        , event = ""
        , today = Nothing
        , titleDate = Nothing
        }


initialCmd : (State -> msg) -> State -> Cmd msg
initialCmd toMsg state =
    let
        stateValue =
            getStateValue state

        setDate now =
            State
                { stateValue
                    | today = Just now
                    , titleDate = Just <| Date.Extra.Core.toFirstOfMonth now
                }
    in
        Task.perform
            (setDate >> toMsg)
            Date.now


getStateValue : State -> StateValue
getStateValue state =
    case state of
        State stateValue ->
            stateValue



-- EVENTS


onChange : (Maybe Date -> msg) -> Html.Attribute msg
onChange tagger =
    Html.Events.on "change" (Json.Decode.map (Date.fromString >> Result.toMaybe >> tagger) Html.Events.targetValue)


onMouseDown : msg -> Html.Attribute msg
onMouseDown msg =
    let
        eventOptions =
            { preventDefault = True
            , stopPropagation = True
            }
    in
        Html.Events.onWithOptions "mousedown" eventOptions (Json.Decode.succeed msg)


onMouseUp : msg -> Html.Attribute msg
onMouseUp msg =
    let
        eventOptions =
            { preventDefault = True
            , stopPropagation = True
            }
    in
        Html.Events.onWithOptions "mouseup" eventOptions (Json.Decode.succeed msg)



-- ACTIONS


switchMode : Options msg -> State -> msg
switchMode options state =
    let
        stateValue =
            getStateValue state
    in
        options.toMsg <| State { stateValue | dialogFocused = False, event = "title" }


gotoNextMonth : Options msg -> State -> msg
gotoNextMonth options state =
    let
        stateValue =
            getStateValue state

        updatedTitleDate =
            Maybe.map (Date.Extra.Duration.add Date.Extra.Duration.Month 1) stateValue.titleDate
    in
        options.toMsg <| State { stateValue | dialogFocused = False, event = "next", titleDate = updatedTitleDate }


gotoPreviousMonth : Options msg -> State -> msg
gotoPreviousMonth options state =
    let
        stateValue =
            getStateValue state

        updatedTitleDate =
            Maybe.map (Date.Extra.Duration.add Date.Extra.Duration.Month -1) stateValue.titleDate
    in
        options.toMsg <| State { stateValue | dialogFocused = False, event = "previous", titleDate = updatedTitleDate }



-- VIEWS


{ id, class, classList } =
    datepickerNamespace


datePicker : Options msg -> List (Html.Attribute msg) -> State -> Maybe Date -> Html msg
datePicker options attributes state currentDate =
    let
        stateValue =
            getStateValue state

        datePickerAttributes =
            attributes
                ++ [ onFocus <| options.toMsg <| State { stateValue | inputFocused = True, event = "onFocus" }
                   , onBlur <|
                        options.toMsg <|
                            State
                                { stateValue
                                    | inputFocused =
                                        if stateValue.dialogFocused then
                                            True
                                        else
                                            False
                                    , event = "onBlur"
                                }
                   , onChange options.onChange
                   ]
    in
        div
            [ class [ DatePicker ]
            ]
            [ input datePickerAttributes []
            , if stateValue.inputFocused || stateValue.dialogFocused then
                datePickerDialog options state currentDate
              else
                text ""
            ]


datePickerDialog : Options msg -> State -> Maybe Date -> Html msg
datePickerDialog options state currentDate =
    let
        stateValue =
            getStateValue state

        title =
            let
                date =
                    case currentDate of
                        Nothing ->
                            stateValue.titleDate

                        Just _ ->
                            currentDate
            in
                span
                    [ class [ Title ]
                    , onMouseUp <| switchMode options state
                    ]
                    [ date
                        |> Maybe.map options.titleFormatter
                        |> Maybe.withDefault "N/A"
                        |> text
                    ]

        previousButton =
            span
                [ class [ ArrowLeft ]
                , onMouseUp <| gotoPreviousMonth options state
                ]
                [ DatePicker.Svg.leftArrow ]

        nextButton =
            span
                [ class [ ArrowRight ]
                , onMouseUp <| gotoNextMonth options state
                ]
                [ DatePicker.Svg.rightArrow ]
    in
        div
            [ onMouseDown <| options.toMsg <| State { stateValue | dialogFocused = True, event = "onMouseDown" }
            , onMouseUp <| options.toMsg <| State { stateValue | dialogFocused = False, inputFocused = True, event = "onMouseUp" }
            , class
                [ Dialog ]
            ]
            [ div [ class [ Header ] ]
                [ previousButton
                , title
                , nextButton
                ]
            , calendar options state currentDate
            , div
                [ class [ Footer ] ]
                [ currentDate |> Maybe.map options.fullDateFormatter |> Maybe.withDefault "" |> text ]
            ]


calendar : Options msg -> State -> Maybe Date -> Html msg
calendar options state currentDate =
    let
        stateValue =
            getStateValue state
    in
        case stateValue.titleDate of
            Nothing ->
                Html.text ""

            Just titleDate ->
                let
                    selectedDate =
                        currentDate
                            |> Maybe.withDefault titleDate

                    firstDay =
                        Date.Extra.Core.toFirstOfMonth selectedDate
                            |> Date.dayOfWeek
                            |> DatePicker.DateUtils.dayToInt options.firstDayOfWeek

                    month =
                        Date.month selectedDate

                    year =
                        Date.year selectedDate

                    days =
                        DatePicker.DateUtils.generateCalendar options.firstDayOfWeek month year

                    header =
                        thead [ class [ DaysOfWeek ] ]
                            [ tr
                                []
                                [ th [] [ text options.nameOfDays.sunday ]
                                , th [] [ text options.nameOfDays.monday ]
                                , th [] [ text options.nameOfDays.tuesday ]
                                , th [] [ text options.nameOfDays.wednesday ]
                                , th [] [ text options.nameOfDays.thursday ]
                                , th [] [ text options.nameOfDays.friday ]
                                , th [] [ text options.nameOfDays.saturday ]
                                ]
                            ]

                    toDay day =
                        td
                            [ class
                                (case day.monthType of
                                    DatePicker.DateUtils.Previous ->
                                        [ PreviousMonth ]

                                    DatePicker.DateUtils.Current ->
                                        [ CurrentMonth ]

                                    DatePicker.DateUtils.Next ->
                                        [ NextMonth ]
                                )
                            , onClick <| options.onChange <| Just <| DatePicker.DateUtils.toDate year month day
                            , onMouseUp <| options.toMsg <| State { stateValue | dialogFocused = False, inputFocused = False, event = "onChange" }
                            ]
                            [ text <| toString day.day ]

                    toWeekRow week =
                        tr [] (List.map toDay week)

                    body =
                        tbody [ class [ Days ] ]
                            (days
                                |> List.Extra.groupsOf 7
                                |> List.map toWeekRow
                            )
                in
                    table [ class [ Calendar ] ]
                        [ header
                        , body
                        ]
